# Forge diagnostics and infrastructure wishlist

Last observed: 2026-10-21 UTC. Project: Atrapa. This is living feedback for Tillandsias forge maintainers and subsequent agent sessions.

## Maintenance and evidence rules

Update this file when a session discovers or resolves a forge issue, changes a workaround, verifies accelerator access, or measures training/runtime limits. Preserve resolved incidents and date new evidence. Separate **observed**, **reported**, **proposed**, and **untested** claims. Never record tokens, credential contents, private keys, authenticated URLs, or complete environment dumps. A capability existing on the host is not proof the forge or a sibling toolchain can use it.

This session only drafted UX/training plans and inspected infrastructure. It did not mount a new volume, start training, access the A5000 host, or deploy to production. The current running app remains the construction landing page.

## Current environment: observed

| Area | Evidence / result | Consequence |
|---|---|---|
| Container | Rootless Podman-style mounts and `/run/.containerenv`; user `forge`, UID/GID 1000 | Host launcher owns mounts and hardware provisioning |
| CPU | `nproc` reports 12; `cpu.max` is `max 100000` | No CPU quota at this cgroup level; host contention and ancestor limits still matter |
| Memory | `memory.max` = 6442450944 bytes (6 GiB); host-visible RAM about 14 GiB | Size batches and workers to container limits, not `free` alone |
| Memory events | `oom` and `oom_kill` counters zero at inspection | No observed cgroup OOM in this run; not a training capacity benchmark |
| Checkout | `/home/forge/src` is 1.5 GiB tmpfs; about 1.2 GiB free | Source/build storage is limited and ephemeral; commit/push source changes |
| Project cache | `/home/forge/.cache/tillandsias-project` is writable, disk-backed btrfs | Existing storage candidate for small artifacts; lifecycle/cleanup policy needs confirmation |
| Cache backing | Podman named volume `tillandsias-forge-cache-atrapa`; backing filesystem about 475 GiB total, 34 GiB free, 93% used | Space is shared with host, not reserved for this project; do not assume a 20 GiB allocation is harmless |
| Temporary storage | `/tmp` 256 MiB tmpfs; `/dev/shm` approximately 63 MiB | Large compiler scratch, datasets, and worker shared memory need explicit paths/budgets |
| Tools | Node 22.23.1, Cargo 1.99.0, OpenSpec 1.14.3 | Development and Rust trainer exploration available |
| Flutter toolchain | Flutter 3.47.7, Dart 3.13.5 through the forge's host-managed toolchain | Works after initial preparation; SDK is not simply installed in this container |
| Wrangler | Project-installed 4.151.3 | Managed local Wrangler preview works |
| Ollama | `http://inference:11434/api/version` responds with 0.34.0; `/api/tags` responds | Sibling model inference is reachable; this is not a training API |
| Host control | Lane MCP socket exists and host-browser service calls succeed | Managed previews, visible browser windows, and toolchain execution available |
| Podman CLI | `command -v podman` found no executable here | Container launch/mount changes must be made on the host or through a supported launcher feature |
| Direct GPU/NPU nodes | Neither `/dev/dri` nor `/dev/accel` exists in this container; no `nvidia-smi` or `vulkaninfo` command found | No demonstrated direct training accelerator access from this forge |

Startup envelope **reports**, rather than this session independently proving: Radeon 840M/860M graphics reachable through the Ollama engine; GPU path DRM; NPU AMD XDNA present but unusable with reason `engine-missing`; unified host memory budget about 15 GB. The envelope's `workstation-gpu` capacity label must not be interpreted as a discrete GPU or permission to use it from an arbitrary trainer. CPU training remains a viable experiment without direct GPU/NPU access.

## Worked as expected out of the box

- Git fetch/commit/push through the enclave mirror and GitHub relay without configuring credentials. Successful pushes explicitly reported durable upstream acceptance. Level 0 branch discipline currently permits main pushes.
- OpenSpec initialization, Codex workflow generation, change scaffolding/status, and strict spec/change validation.
- Flutter project generation for web, Android, iOS, Linux, macOS, and Windows once the opt-in toolchain was ready. Runner generation is not proof of native SDK builds or signing.
- Flame dependency resolution, Flutter analysis, widget tests, and release web compilation.
- npm dependency installation and outbound official documentation access through the provided networking path.
- Managed `publish_local` using Wrangler: serving, watched assets, route readiness, local TLS host trust, and project-local browser access.
- Visible desktop and Galaxy S24-emulated Chromium windows, screenshots and console inspection. The human could resize the window. Mobile emulation is not a physical-device performance test.
- Ollama discovery endpoint responded with six cached models: Qwen2.5 0.5B/7B, Llama3.2 3B, and three embedding models. No generation-throughput or training test was performed.
- Disk-backed project cache is already mounted. Earlier advice that implied no persistent storage existed was incomplete; retention guarantees and cross-toolchain sharing remain unknown.

## Slightly broken, recovered, or surprising

### D-001: OpenSpec date rejected by forge YAML gate — resolved locally

OpenSpec generated `.openspec.yaml` with `created: 2026-10-21`. Local strict OpenSpec validation passed, but the remote pre-receive Ruby/Psych YAML loader rejected the document while resolving its date scalar. Quoting it as `created: "2026-10-21"` allowed the next push to succeed.

Maintainer request: accept normal YAML timestamps safely or ensure scaffolded metadata is compatible with the gate; emit a short actionable error instead of a long Ruby stack trace. Reproduce using a freshly scaffolded change with an unquoted ISO date and compare local validation with push validation. Keep the fix compatible with safe parsing rather than disabling validation.

### D-002: Browser font fallback and blocked external glyph assets — resolved for current page

The first visible build rendered two decorative symbols as missing glyphs and attempted external Google font fallback, which failed in the project-restricted browser. Removed those symbols and rebuilt with `--no-web-resources-cdn` to keep rendering assets local. Reviewed the subsequent visible page; this does not prove support for arbitrary future scripts/glyphs or a fully offline reload.

Maintainer request: surface browser network policy and asset self-hosting guidance near preview setup; provide a local font strategy for multilingual apps. The blocked network is an intentional boundary, not evidence the browser is generally broken.

### D-003: Flutter preparation looks idle during download — eventually worked

The first `flutter --version` triggered host image preparation. Status stayed on step 11/14, downloading, for a noticeable interval before the image became ready. The command eventually completed and generation/build/tests worked. `toolchain_prepare` exposed state and elapsed time, which helped.

Maintainer request: preserve nonblocking preparation/status, add byte/progress or heartbeat information and make cold-start expectations clear. Initial latency is not a permanent Flutter failure.

### D-004: Host RAM and container RAM differ — observed, not a fault

`free -h` shows the host memory pool while the forge is limited to 6 GiB. Training recommendations based only on host totals would overestimate capacity. Expose effective cgroup CPU/RAM/scratch budgets alongside the host accelerator envelope.

### D-005: Small portrait overflow — application defect, fixed

An initial 320-pixel widget test caught a header overflow. A wrapping header fixed it, and both viewport tests passed. This is useful validation evidence, not a forge defect. Distinguish app errors from infrastructure incidents.

## Required figuring out

- `flutter` is a host-managed wrapper; filesystem, device, and artifact mounts available to its sibling execution environment may differ from this shell. Confirm access to any new training/artifact mount in every consumer.
- A managed Wrangler service is published with `publish_local {category: WEB, runtime: wrangler}`. It is local-only and does not authenticate or deploy to Cloudflare. Reuse the managed service rather than start competing servers. Its current reported address is `https://www.atrapa.localhost:18443`.
- The host browser deliberately restricts network access. A browser failing to download public fonts cannot be diagnosed solely from command-line curl success.
- The repository lives on tmpfs while the project cache is a host-disk named volume. Git durability and checkpoint durability need separate handling.
- Dropping stale AI results does not interrupt their computation. Bounded admission, worker lifecycle, and measurements are still needed even with actor-style messaging and WASM.
- GPU availability through Ollama does not expose a general training device. Ollama imports/serves models; our small numeric policy needs its own gradient-training process.
- Python is present but the forge's declared automation policy prohibits committed Python automation. Do not silently choose a Python-based trainer. A supported Rust CPU/GPU training toolchain or an explicitly resolved policy/toolchain path is needed; Rust framework compatibility is not yet tested.

## Not working or missing for the proposed workload

These are gaps relative to Atrapa training/live viewing, not claims that all are promised forge features.

| Gap | Current evidence | Requested resolution / acceptance test |
|---|---|---|
| Direct accelerator training | Device nodes/tools absent here; sibling Ollama only | Opt-in training service/container with selected backend; run a real gradient update and report device used |
| NPU engine | Startup envelope says `engine-missing` | State supported model/backend capabilities; NPU is optional and not a blocker for CPU/CUDA work |
| Dedicated artifacts mount | Existing cache has unverified retention/cleanup and shared disk nearly full | Document protected artifacts namespace or add explicit host working-directory bind mount; verify persistence across forge recreation |
| Durable jobs | Tool session handles are available, but job survival across forge teardown is untested | Host-managed detached jobs with logs, status, checkpoint/resume and cancellation; test forge shutdown/reconnect |
| Fleet job API | No remote A5000 access, allocation or training service tested | Authenticated resource-scoped job submission, pinned environments, resumable artifacts, and status/log tools |
| Remote live episode feed | No simulator/training stream implemented | Serve selected versioned episode snapshots/events through a project-authorized route; browser never needs a public training API |
| Physical mobile profiling | Only emulated mobile browser inspected | Document phone-access preview flow and collect actual Android/iOS performance; emulation alone cannot qualify a model |
| Storage budget discoverability | Capacity exposed as raw mounts/cgroups, not a single product view | Report effective memory, tmpfs, artifact retention, disk quota and available bytes in startup context |
| Trainer/export compatibility | No training framework or export pipeline smoke test | Reuse authoritative simulator, train a tiny model, export weights, and compare browser/native outputs |

## Mounting a host working directory

Run Podman commands on the **host**, not in this forge. This documents the launch change; it was not executed. The Tillandsias launcher must preserve its existing networking, identities, sockets, secrets and mounts when recreating a forge. There is no verified launcher UI/config key for extra mounts available to this agent; do not invent one or replace the managed launch with a bare `podman run`.

1. Inspect the host's existing container and mounts:

   ```sh
   podman ps --format '{{.Names}}\t{{.Image}}'
   podman inspect <forge-container-name> --format '{{json .Mounts}}'
   podman volume inspect tillandsias-forge-cache-atrapa
   ```

2. Create a dedicated host directory:

   ```sh
   mkdir -p "$HOME/atrapa-work"
   ```

3. Ask the launcher to include this additional volume option in its existing `podman create/run` configuration:

   ```sh
   --volume "$HOME/atrapa-work:/work/atrapa:rw,z"
   ```

   Use `:z` when the forge and training/toolchain containers share this directory on SELinux hosts. For a directory private to one container, `:Z` gives private labeling. Relabel only the dedicated directory, not the entire home directory. Preserve the launcher's existing user namespace; UID/GID 1000 inside does not establish the host mapping. `--userns=keep-id` is a possible launcher-level strategy, not an option to append blindly to an existing mapping. Avoid `:U` unless recursive host ownership changes are explicitly intended.

4. Recreate the forge through its launcher with existing source work pushed first. New bind mounts normally belong to container creation; `podman exec` does not add a persistent mount to the existing launch specification. Restarting the same unchanged container will not add it either. Test the directory is writable from the forge and every training/toolchain consumer, then verify a sentinel/checkpoint survives recreation.

5. Configure future training jobs with an explicit artifact path such as `ATRAPA_TRAINING_DIR=/work/atrapa`. Keep datasets, checkpoints, run logs and exported large artifacts there, outside the source tree and public static-assets directory. Commit only small selected model bundles when appropriate; store large artifacts by hash in durable storage.

A possible short-term path is `/home/forge/.cache/tillandsias-project/atrapa-training`, if maintainers confirm that namespace survives cleanup and is suitable for user data. It is not created here, and cache != backup. Existing free disk does not imply an allocated training quota.

Podman reference: https://docs.podman.io/en/latest/markdown/podman-run.1.html

## Proposed A5000 Tillandsias training lane

The operator reports a 20-core Intel i9, 64 GB RAM, and a 24 GB NVIDIA RTX A5000. Access, actual available capacity, driver/runtime versions and job contention have not been verified. A similar Tillandsias stack could provide the following without enlarging every ordinary coding forge:

- A dedicated opt-in sibling **training lane** rather than requiring CUDA inside the coding container. Let the CPU forge build/edit/test and submit versioned jobs; run gradient updates on the GPU host.
- Host NVIDIA driver and NVIDIA Container Toolkit/CDI configuration. Select a GPU explicitly, expose it to the trainer container and use a compatible pinned CUDA training image/backend. Do not assume GPU passthrough merely because an Ollama service can infer on that host.
- Host verification using `nvidia-smi`, CDI device discovery, and a container-level training smoke test. NVIDIA documents Podman `--device nvidia.com/gpu=all`; select a particular GPU where appropriate and follow the host's SELinux policy. The official example includes `--security-opt=label=disable`; that is a host provisioning decision, not a blanket recommendation to weaken this forge.
- Configurable cgroup budgets appropriate to the job. An initial proposal for this 64 GB host is roughly 16–32 GB trainer RAM and 4–12 CPU workers, adjusted from measurement and other host services. Do not inherit this laptop forge's 6 GiB limit by accident or equate 24 GB VRAM with free capacity.
- Persistent fast disk for checkpoints/data/toolchain caches; proposed initial allocation 50–100 GB on that host with quota, retention and low-space reporting. Smaller CPU experiments can begin with much less. These are planning allowances, not measured minimum requirements.
- Share or fetch the same versioned authoritative simulator and schemas. Support CPU rollout workers, a GPU learner, larger teachers/search and student distillation without a second gameplay implementation.
- Job manifests pin source revision, toolchain image digest, dataset/schema/model hashes, seeds and resource limits. Use bounded job queues, checkpoint/resume, clean cancellation, logs, progress and artifact checksums. No Kubernetes requirement.
- An authenticated artifact/status transport usable from this forge: host tool API or restricted SSH/job runner, with credentials managed outside the repository. A mounted local path on one machine does not automatically share files with another machine.
- A bounded sampled episode channel for viewing selected training matches locally. Include run/episode/policy/rules IDs and source ticks; keep final outcomes reliable and let obsolete render snapshots drop. Viewer disconnects must not stop training.
- A complete acceptance demonstration: submit tiny CPU and CUDA jobs, record actual backend and throughput, reconnect after session restart, retrieve/check hashes, export small weights, watch an episode, and compare exported inference against the training model. No performance promise before that demonstration.

NVIDIA reference: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html

## Live-match UX and headless-training overlap

The planning change `openspec/changes/grid-game-and-local-ai/` now includes a draft live-view contract and UX flow. Implementation is not started.

| Shared facility | Player use | Training viewer use | Roadblock to catch early |
|---|---|---|---|
| Authoritative state/schema | Human vs bots | Selected live or recorded episode | Schema/rules mismatch must be visible, never silently reinterpreted |
| Flame arena renderer | Keyboard and portrait touch play | Same board, snakes and resource HUD | Rendering must not become a dependency of headless throughput |
| Simulation clock | Flame dt drives local play | Flame paces a local exhibition/replay; remote episode owns its source ticks | Never drive an external training episode with a browser clock |
| Snapshot/event channels | Responsive HUD | Latest visual state plus reliable outcome | Dropping visual snapshots must not drop learning transitions or authoritative events |
| Controls | Bottom directional pad and resource cues | Watch controls replace touchpad | Input must not accidentally control an observed AI |
| Model identity/status | Honest loading/fallback indication | Run/episode/policy version and speed/lag | A replay, baseline bot and live learned policy must be distinguishable |
| Restart/pause | Local match commands | Viewer pause/detach or local exhibition pause | Pausing a viewer must not pause shared/remote training |

## Session log

- **2026-10-21 — Bootstrap:** OpenSpec, Flutter/Flame and all platform runners initialized; responsive construction page built; tests/analyze/web release passed; managed Wrangler preview and visible browsers worked. D-001 YAML metadata and D-002 glyph issues resolved with documented workarounds; D-003 cold toolchain preparation completed.
- **2026-10-21 — Planning:** Grid gameplay, bounded inference, local policy and offline training specs/plans committed. No trained model or gameplay implementation yet.
- **2026-10-21 — Infra/UX diagnostics:** Verified CPU/cgroup/tmpfs/cache mounts and Ollama endpoint; discovered cache is disk-backed and backing disk has about 34 GiB free. Documented dedicated bind mount, training-lane wishlist, and live match viewing UX. No host/container configuration changed and no remote messages/jobs submitted.
