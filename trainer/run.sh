#!/usr/bin/env bash
# Run the PROVISIONAL toy-grid training smoke. Usage:
#   trainer/run.sh cpu    # host cargo, CPU
#   trainer/run.sh cuda   # pinned CUDA devel image via podman + NVIDIA CDI
# Extra args are passed to the trainer (e.g. --steps 4000 --batch 8192).
# Scratch and caches stay under the repo's gitignored target/.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-cpu}"; shift || true
IMAGE="docker.io/nvidia/cuda:12.6.3-devel-ubuntu24.04@sha256:badf6c452e8b1efea49d0bb956bef78adcf60e7f87ac77333208205f00ac9ade"
case "$mode" in
  cpu)
    CARGO_TARGET_DIR="$repo/target/train-smoke/cpu" nice -n 10 cargo run --release -j 8 \
      --manifest-path "$repo/trainer/Cargo.toml" -- --device cpu --out "$repo/target/train-smoke/out-cpu" "$@" ;;
  cuda)
    mkdir -p "$repo/target/train-smoke/cargo-home"
    # Reuse the host's rustup toolchain read-only; CUDA_COMPUTE_CAP 86 = RTX A5000.
    nice -n 10 podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable \
      -v "$HOME/.rustup:/opt/rustup:ro" -v "$HOME/.cargo/bin:/opt/cargo-bin:ro" \
      -v "$repo:/w" -w /w \
      -e RUSTUP_HOME=/opt/rustup -e CARGO_HOME=/w/target/train-smoke/cargo-home \
      -e PATH=/opt/cargo-bin:/usr/local/cuda/bin:/usr/bin:/bin -e CUDA_COMPUTE_CAP=86 \
      -e CARGO_TARGET_DIR=/w/target/train-smoke/cuda \
      "$IMAGE" bash -c 'nvidia-smi --query-gpu=name,driver_version --format=csv,noheader && cargo run --release -j 8 --features cuda --manifest-path trainer/Cargo.toml -- --device cuda --out target/train-smoke/out-cuda "$@"' _ "$@" ;;
  *) echo "usage: $0 cpu|cuda [trainer args]" >&2; exit 2 ;;
esac
