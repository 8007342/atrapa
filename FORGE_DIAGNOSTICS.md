# Forge diagnostics and infrastructure wishlist

Last observed: 2026-10-22 UTC. Project: Atrapa. This is living feedback for Tillandsias forge maintainers and subsequent agent sessions.

## Maintenance and evidence rules

Update this file when a session discovers or resolves a forge issue, changes a workaround, verifies accelerator access, or measures training/runtime limits. Preserve resolved incidents and date new evidence. Separate **observed**, **reported**, **proposed**, and **untested** claims. Never record tokens, credential contents, private keys, authenticated URLs, or complete environment dumps. A capability existing on the host is not proof the forge or a sibling toolchain can use it.

Sessions so far drafted UX/training plans, exercised the cache, and implemented the first playable Flame slice with a shared pure-Dart rules engine. The work-branch development preview exposes /play; default production builds retain construction only. No new volume was mounted, no gameplay policy was trained on the laptop, no A5000 host was accessed from this forge, and no production deployment occurred. Macuahuitl supplied its separate GPU smoke evidence below.

## Current environment: observed

| Area | Evidence / result | Consequence |
|---|---|---|
| Container | Rootless Podman-style mounts and `/run/.containerenv`; user `forge`, UID/GID 1000 | Host launcher owns mounts and hardware provisioning |
| CPU | `nproc` reports 12; `cpu.max` is `max 100000` | No CPU quota at this cgroup level; host contention and ancestor limits still matter |
| Memory | `memory.max` = 6442450944 bytes (6 GiB); host-visible RAM about 14 GiB | Size batches and workers to container limits, not `free` alone |
| Memory events | `oom` and `oom_kill` counters zero at inspection | No observed cgroup OOM in this run; not a training capacity benchmark |
| Checkout | `/home/forge/src` is 1.5 GiB tmpfs; about 1.2 GiB free | Source/build storage is limited and ephemeral; commit/push source changes |
| Project cache | `/home/forge/.cache/tillandsias-project` is writable, disk-backed btrfs | Byte-verified I/O and cross-toolchain sharing now tested; teardown retention/cleanup policy still needs confirmation |
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

### D-006: Direct accelerator training lane on macuahuitl — observed 2026-10-21

**Scope:** infrastructure proof only. Per the design review (`review-2026-10-21.md` R1/R4/R6) the rules core, first trainer and browser evaluator are expected to be pure Dart; the GPU path is **optional** and this Rust crate is not the project trainer. Environment is a PROVISIONAL toy grid (8x8, imitate a "reduce Manhattan distance" teacher); it does not use Atrapa rules (1.2/1.3 open) or a shared headless transition (2.1 not built), so it does not close task 6.1.

**Observed** on bare-metal host macuahuitl (not the coding forge), rootless Podman with NVIDIA CDI (`nvidia.com/gpu=all`):

| Item | Value |
|---|---|
| GPU | NVIDIA RTX A5000, 24564 MiB, driver 615.71.09 |
| Image | `docker.io/nvidia/cuda:12.6.3-devel-ubuntu24.04@sha256:badf6c452e8b1efea49d0bb956bef78adcf60e7f87ac77333208205f00ac9ade` |
| Trainer | `trainer/` (Rust, candle 0.9.2, AdamW), MLP 128-64-4, 8516 params, 34064 B f32 |
| Job | 2000 steps x 4096 samples, seed 42; run with `trainer/run.sh cpu` / `trainer/run.sh cuda` |
| CPU (host, `nice -n 10`) | device_used=cpu, 14.26 s training wall, ~574k samples/s, loss 1.41 -> 0.0011, held-out acc 0.23 -> 1.00 |
| CUDA (container) | device_used=cuda:0, 2.20 s training wall, ~3.73M samples/s (~6.5x CPU), loss 1.39 -> 0.0009, acc 0.28 -> 1.00; cold container build 33 s |
| Export | `weights.f32` (flat LE f32: l1.weight[64,128] row-major, l1.bias, l2.weight[4,64], l2.bias) + `manifest.json` (shapes, dtype, sha256, provenance, 4 reference-logit fixtures) |
| Parity | plain-Rust `reference_forward` vs candle over 2048 held-out observations: max abs diff 7.6e-6 (tol 1e-4), 100% action agreement, on both devices |

Wall times are a tiny-model regime with the host land queue possibly active; they are not a capacity benchmark. CPU and CUDA runs share seed but initialise weights with device-specific RNG, so their weight hashes differ (not bit-reproducible across devices).

**Still missing:** training on the shared authoritative transition (Dart, after 1.2/1.3 and 2.1); a Dart evaluator parity test against `manifest.json` fixtures (5.3); GPU access from the coding forge itself (this ran on the host); durable/detached jobs, artifact retention and a fleet job API; per-device bit-reproducibility; the CUDA run reuses the host rustup toolchain read-only rather than a toolchain pinned in the image.

### D-007: GitHub PR creation unavailable from this forge — open

Observed 2026-10-22: the connected GitHub get-repository tool succeeded and reported repository access, but create-pull-request returned HTTP403 `Resource not accessible by integration`. Local `gh auth status` reports no authenticated host, consistent with the shipped forge gh cheatsheet: Git credentials live behind the mirror, not in the coding forge. Branch pushes through the mirror succeeded. No secret extraction, token setup, or direct push bypass was attempted.

Impact: source is durably on `work/forge-play`, but the required PR into `game` could not be opened by this lane. Exact PR text and compare link are saved in `plan/forge-play-pr.md`. Maintainer wishlist: a scoped host-owned PR create/read/status API using existing repository authorization without handing tokens to the agent. Verify create/read/merge permissions separately from repository reads and git push. This is an authorization limitation, not an automatic approval-review rejection.

### D-008: Browser window handles can outlive a usable page — recovered

Earlier listed window IDs returned `WINDOW_NOT_RUNNING: the window has no page` during 2026-10-22 verification. Opening fresh visible desktop/portrait windows worked; the operator confirmed seeing snakes playing. Cause (manual close, host lifecycle, or stale listing) was not established. Do not claim a browser crash from this alone. Useful improvement: window listing should expose usable-page/lifecycle state, with guidance on when to reopen.

### D-009: Fleet inbox tool had no lane — open, nonblocking

The fleet inbox read tool returned `refused:msg:no-lane` when inspecting Claude's handoff. Git fetch and committed game-branch rulings/review supplied the handoff instead; no messages were sent. Check consistency of lane attribution between the forge and MCP execution before advertising fleet inbox availability.

### D-010: Branch grammar advice differs from operator workflow — advisory

The mirror accepted `work/forge-play` but warned its branch-creation grammar expected work/order-style refs. The committed operator ruling explicitly uses `work/<topic>` PRs into `game`. No guard was bypassed; the warning was advisory. Align project-declared grammar and mirror advice so accepted collaboration conventions do not produce misleading warnings.

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
| Direct accelerator training | Forge: device nodes absent. Host macuahuitl: CUDA gradient training observed 2026-10-21 (D-006); optional per review | Opt-in training service/container with selected backend; run a real gradient update and report device used |
| NPU engine | Startup envelope says `engine-missing` | State supported model/backend capabilities; NPU is optional and not a blocker for CPU/CUDA work |
| Dedicated artifacts mount | Existing cache passed real writes, independent-process reads and sibling Flutter access; teardown retention remains unverified | Existing cache is sufficient to start small jobs; document retention/protected namespace and test later-session persistence |
| Durable jobs | Tool session handles are available, but job survival across forge teardown is untested | Host-managed detached jobs with logs, status, checkpoint/resume and cancellation; test forge shutdown/reconnect |
| Fleet job API | No remote A5000 access, allocation or training service tested | Authenticated resource-scoped job submission, pinned environments, resumable artifacts, and status/log tools |
| Remote live episode feed | No simulator/training stream implemented | Serve selected versioned episode snapshots/events through a project-authorized route; browser never needs a public training API |
| Physical mobile profiling | Only emulated mobile browser inspected | Document phone-access preview flow and collect actual Android/iOS performance; emulation alone cannot qualify a model |
| Storage budget discoverability | Capacity exposed as raw mounts/cgroups, not a single product view | Report effective memory, tmpfs, artifact retention, disk quota and available bytes in startup context |
| Trainer/export compatibility | Synthetic plain-Dart CPU gradient/checkpoint/resume probe passed; full framework/game integration untested | Reuse authoritative simulator, qualify a trainer/backend, and compare browser/native policy outputs |

## Running-container mounts and using the existing cache

**Operator correction:** the Tillandsias forge launcher has no extra-mount override parameters. Earlier guidance to ask the launcher to append a volume option was not an actionable path in this stack. Preserve this correction in future advice.

Podman does not expose an ordinary supported hot-add bind-volume option through `podman update`; that command changes resource/healthcheck configuration. `podman mount` exposes a container's root filesystem on the host; it does not insert a host directory into a running container. Host administrators can sometimes inject a transient mount through Linux namespace tools, but permissions, rootless mappings, SELinux and restart persistence make this host-specific. It is not needed for the successful cache experiment, and no namespace/mount changes were attempted.

Use the volume already mounted at:

`/home/forge/.cache/tillandsias-project/atrapa-training`

A dedicated probe subdirectory was actually created, populated, read and used for CPU checkpointing. The host-managed Flutter toolchain can read and write the same path. No forge restart or new mount was required. This is enough to start small data-generation and CPU-learning experiments while storage remains bounded. The mounted volume is `tillandsias-forge-cache-atrapa`; maintainers should document its cleanup policy rather than treat an unverified policy as a reason to block all work.

Host-side read-only inspection, if useful to the operator:

```sh
podman ps --format '{{.Names}}\t{{.Image}}'
podman inspect <forge-container-name> --format '{{json .Mounts}}'
podman volume inspect tillandsias-forge-cache-atrapa
```

Keep data/checkpoints outside the tmpfs checkout and public web assets. Use an explicit run directory, bound dataset growth, and retain the hashes/manifests in Git. Cache is not backup; a future session must verify retained artifacts before overwriting them. Avoid using the cache root as scratch or cleaning other tools' caches. No claim of retention across teardown or power-loss durability follows from same-session file flush/rename tests.

References:

- https://docs.podman.io/en/latest/markdown/podman-update.1.html
- https://docs.podman.io/en/latest/markdown/podman-mount.1.html

## Executed cache and CPU-learning experiment

Run: `session-20261021-a`, 2026-10-21 UTC. Source and exact reproduction commands: [tool/README.md](tool/README.md). Committed measured output and artifact SHA-256 hashes: [plan/experiments/forge-cache-2026-10-21.json](plan/experiments/forge-cache-2026-10-21.json).

| Experiment | Observed result | What it establishes |
|---|---|---|
| Patterned 8 MiB payload | Write + flush + rename about 43.3 ms; separate-process read/byte verification about 34.2 ms | Writable disk-backed artifacts, independent process access and deterministic content; timings include warm-cache effects and are not throughput guarantees |
| Tiny 2–8–1 XOR network, 33 parameters | CPU gradient descent, 6,000 epochs; mean cross-entropy 0.731669 -> 0.0004485 | Real weight updates and a serializable checkpoint can run now without GPU, Ollama or extra framework dependencies |
| Independent-process resume | Resume to 12,000 epochs; loss 0.0002141; every weight exactly matched uninterrupted reference | Checkpoint load/resume works for the deterministic plain-Dart fixture |
| Sibling Flutter access | Opt-in Flutter test verified payload and checkpoint, then wrote a receipt that the forge read | The existing mount is shared with this host-managed toolchain in this lane |
| Data footprint | About 8.1 MiB including payload/checkpoints/reports | A bounded probe can run without allocating multi-gigabyte datasets |

This is **synthetic infrastructure qualification**, not a trained snake policy, RL throughput benchmark, trainer-framework qualification, export-to-WASM test or detached-job survival proof. The toy probe uses manual gradient descent in Dart to avoid framework-install cost and isolate basic capabilities. Dedicated training framework selection remains open. Per-process RSS in the saved probe results is roughly 170–175 MB; it is not a future training memory requirement.

Immediate usable next steps: implement shared headless transition fixtures, generate bounded seeded episodes into the cache, bring up local baseline exhibitions with the shared renderer, and then qualify the chosen trainer against that exact simulation. Existing input/gameplay review gates still apply to behavior dependent on unconfirmed rules. None of this requires waiting for the A5000 host; its feedback can shape larger jobs and backend selection in parallel.

## Optional future A5000 training lane (not needed for Slice A)

Macuahuitl reported and tested the A5000 lane as recorded in D-006. The later ruling assigns gameplay training/retraining to that host and app/rules evolution to Codex. For Slice A a normal shared-rules checkout and exported assets suffice; the wishlist below is optional future infrastructure, not a prerequisite or request to recreate this forge. The coding forge has not independently accessed the remote host.

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

The accepted review/operator rulings narrow the active change to a playable development slice. Local play is implemented on work/forge-play with shared renderer/rules, but remote live training viewing is deferred. The table below retains future overlap analysis; it is not a claim that a live feed is implemented.

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
- **2026-10-21 — GPU lane smoke (macuahuitl):** Rust/candle toy-grid MLP trained on CUDA (RTX A5000, pinned image digest) and CPU; flat f32 + manifest export with reference-forward parity. Infrastructure proof only; GPU optional per review. See D-006.

- **2026-10-21 — Cache boundary exercise:** Created an 8.1 MiB cache probe; verified 8 MiB payload across processes; trained/resumed synthetic XOR weights with exact checkpoint parity; host-managed Flutter read/wrote same cache successfully. Added reproducible probes and evidence report. Operator confirmed launcher has no mount override; extra mount is not needed for these experiments. Teardown retention remains to be checked in a later session.

- **2026-10-22 — Playable slice:** Shared pure-Dart rules, growing snakes/collisions/golden replay, free-space baseline, flag-gated /play, keyboard/touch and two-human controls, safe lifecycle pause and defensive local policy evaluation implemented. Default/dev web builds passed; desktop/portrait preview checked and operator saw snakes playing. No laptop training. Synthetic browser 252–64–3 benchmark measured 50us p95 per averaged three-forward-pass batch; see docs/measurements/forge-play.md for limitations. Compatible host weights and physical-phone qualification remain pending. Branch pushed; PR creation denied (D-007).

- 2026-10-22 user feedback: survival-only baseline is insufficient as the final opponent. Designer handoff is recorded in docs/winning-ai.md and the training spec; macuahuitl should optimize competitive wins and report terminal outcomes. No new gameplay training ran in this forge.

- 2026-10-22 coordination workaround: user authorized durable Git messages in inbox.d/ and direct integration pushes to game. Added a dated compute-host handoff and repository instructions. This resolves coordination and landing needs without requiring fleet messaging or GitHub PR permissions; those tool limitations remain observed. Git handoffs do not establish recipient acknowledgement.
