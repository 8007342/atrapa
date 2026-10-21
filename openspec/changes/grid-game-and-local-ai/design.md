# Design

## Context

See proposal.md for motivation. The current `lib/game/atrapa_game.dart` is a render-only Flame canvas. `lib/main.dart` mounts it behind a construction screen; tests cover only that screen at two widths. Flutter runners exist for six platforms; Flame is constrained to ^1.38.2. No simulation, AI runtime, or training tools currently exist. This document proposes future implementation; it does not describe deployed functionality.

## Goals / Non-Goals

**Goals:** Define shared timing and command contracts; isolate inference from authoritative match state; compare small local policies with measured browser costs; train reproducible policies offline. Preserve the user's explicit requirement to reuse Flame facilities.

**Non-Goals:** Final art/storyboard, complete campaign, new vendor API dependency, in-browser training, an Erlang/BEAM port, distributed match servers, and automatic fleet job dispatch. WASM is an inference candidate, not an actor runtime by itself.

## Decisions

### 1. Flame owns the running game's lifecycle

Use Flame's `update(dt)`, pause/resume, component lifecycle, resize/camera facilities, input handling, and timer/effect components where their semantics fit. Audit the installed package APIs before adding helpers. No independent periodic game loop, replacement timer library, or wall-clock gameplay scheduler.

A small grid stepper consumes the simulation delta supplied by Flame. It owns cell coordinates, 3–5 substeps per cell, progress, and boundary eligibility: domain logic not supplied by the engine. Headless training calls this same transition logic with explicit deltas and seeds; it does not launch a second clock beside Flame. Timer-driven resource effects must also advance reproducibly in headless execution using the same timer semantics. Wall-clock instrumentation measures inference and frames only; it never spends resources or advances a snake.

Alternative: another reactive framework drives physics. Rejected because it duplicates Flame and creates competing time sources.

### 2. Grid movement and temporal semantics

Represent logical positions in cell/substep space, independently of screen pixels. Initial profiles configure an integer 3–5 substeps per cell. Substep frequency is a separate, unset tuning parameter, not 3–5 cells/second. A small arena and slow initial rate teach controls; level profiles increase baseline visual movement rate. Resizing changes projection and touch layout, not board topology or speed.

Turns commit at cell boundaries. A single boundary consumes at most one queued turn; no series of late turns is replayed. Speeds and resource drain integrate in simulation time. The user-confirmed effects are forward acceleration to a cap, expensive finite braking above a positive floor, exhaustible acceleration, and temporary powerup extensions. Constants and recovery profiles require playtesting; no numbers are invented here.

Process crossed substeps/boundaries in order so a large dt cannot skip a wall or occupied segment. Compute simultaneous movement intents from a common pre-transition state before resolving collisions; the policy for contested destinations and head swaps is a gameplay review gate. Flame hitboxes/callbacks can support presentation or continuous contact where appropriate; exact grid occupancy belongs to the authoritative transition because frame overlap alone can tunnel and offline rules must match.

Pause when backgrounded through Flame lifecycle facilities; invalidate outstanding decisions and reset elapsed-time handling on resume. Ordinary frame variation must preserve logical outcomes for equal accepted simulation time. A configured catch-up bound pauses/reports overload rather than skipping collision checks or processing an unbounded burst.

### 3. Shared controls, with explicit semantic review gates

Keyboard arrows and the bottom mobile touchpad feed one command interpreter used by bots. Relative coast/left/right/boost/brake are a candidate policy vocabulary, subject to the same input timing and authority as humans. A one-shot turn is different from a held speed modifier; never apply a relative left on every physics tick merely because inference has not returned.

Before implementing the interpreter or generating teacher data, resolve and record: tap versus hold/repeat behavior; whether holding a just-turned direction begins boosting; command replacement at a boundary; release behavior and resource recovery; powerup extension/stacking/expiry behavior. These are explicit dependency tasks, not permissions to invent defaults. Contracts above remain at confirmed behavior until that review. No self-collision, body growth, scoring, victory, or level unlock mechanics are specified. Collision tie policy and any training episode objective must be reviewed before those behaviors or final policy training are implemented. Earlier infrastructure and controlled benchmark fixtures do not require a final campaign.

### 4. Actor-style ownership and bounded delivery

Use lightweight ownership boundaries, not a mandatory actor framework: authoritative match owner; human input adapter; decision scheduler; inference service; rendering/HUD observers; model-loading supervisor. Start with Dart streams and bounded mailboxes where suitable. Flame remains the only gameplay time source.

| Message | Delivery | Backpressure policy |
|---|---|---|
| Observation snapshot | Immutable broadcast | One latest snapshot per slow consumer; overwrite pending old snapshots |
| Inference request | Versioned, bounded work | Initially one batch in flight plus one replaceable pending batch; tune measured batching |
| Decision result | Match/agent identity, observation tick, heading version, target boundary, expiry | Validate once; drop stale, superseded, dead-agent, reset-match results |
| Command and resource mutation | Authoritative ordered transition | Bounded per-input state; no arbitrary lossy broadcast |
| Loss, match end, restart | Reliable ordered event | Retain until consumed/acknowledged or dispose the match explicitly |

A slow observer cannot block match advancement. Reliable event queues also need bounds and consumer lifecycle cleanup; do not trade an inference backlog for an unbounded event backlog. Closing a match invalidates its generation, subscriptions, pending work, and model state. Supervision restarts a failed inference worker with bounded retry/backoff; repeated failure exposes baseline-only mode instead of restarting indefinitely.

Dropping a result does not cancel consumed CPU. Admission control prevents obsolete pending work, deadlines reject old answers, and backend cancellation or worker restart is used only if supported and worth its measured cost. Repeated worker termination can cost more than finishing a tiny forward pass.

### 5. Cadence, level speed, and fairness are separate

Physics, rendering, level speed, and decision cadence are distinct. The internal/display mapping is EASY -> HARD, MEDIUM -> HARDER, HARD -> HARDERER. Schedule eligible decision opportunities targeting upcoming cell boundaries; give higher tiers more opportunities within a measured viable range. Do not mandate one inference per visual substep or assume cadence alone guarantees greater strength.

A request carries match generation, agent ID, state/schema versions, observation tick, intended application opportunity/boundary, and expiry. For agents due together, snapshot everyone before applying any decisions. Application is at the specified simulation opportunity, not whenever a promise completes. Early results wait; late results are discarded. Continuing the accepted heading is the default deadline behavior, with speed-command release/expiry following the reviewed shared input contract. Do not insert a perfect collision-avoidance controller that erases difficulty differences.

Warmup and sustained benchmarks estimate completion margin before boundaries at each level/max boost. Cadence changes stay within tested tier ranges with hysteresis. If load cannot support the selected tier, reduce optional rendering cost/work or report an explicit supported profile/fallback; do not silently relabel weak behavior HARDERER. Inference timing and all-bot p95 cost are recorded separately from player skill. There is no automatic rubber-banding to prevent a human win.

### 6. Policy contract and runtime selection

Use versioned numerical observations, independent of art. Candidates include own speed/heading/reserves/effect timers, obstacle occupancy or rays, nearby opponent position/heading/speed with presence masks, powerups, and decision interval/age. Define visibility explicitly; no human future inputs or hidden opponent intents. A coarse spatial encoder is evaluated if rays cannot represent corridors and traps. Stable normalization, maximum counts, masks, and ordering must be frozen before a particular training run.

Output a bounded action distribution and selected valid command. Probability concentration is not calibrated confidence or collision probability without separate evidence. Share weights across bots; keep per-agent random state and any recurrent memory separate. Prefer a feedforward MLP initially to simplify stale-result handling; larger/recurrent/CNN candidates must earn complexity through evaluation.

An initial experimental weight target is 10K–100K parameters (40–400 KB raw FP32), not a guarantee of quality or a cap on teacher size. Compare identical exported policies in a small Dart evaluator and a browser worker running a WASM inference backend. Keep observations/actions backend-neutral. Choose the smallest complete bundle meeting recorded quality/performance thresholds; count runtime, worker, tokenizer if any, metadata, model and peak memory, not weights alone. WebGPU is an optional measured alternative, never a browser prerequisite. Native adapters can reuse model contracts; each target still requires validation.

Host matching versioned assets locally through existing Wrangler static assets. Validate manifest hashes, schema, tensor shapes, normalization and action vocabulary before activating a bundle. Warm up once; keep a deterministic baseline bot available during loading/failure. Offline operation requires an explicit app/runtime/model cache strategy and tests; static hosting alone does not establish offline support. Any threaded-WASM isolation headers must be justified by measurements and checked with Flutter/assets; single-threaded worker inference does not require multithreaded shared memory.

### 7. Offline training and fleet execution

Reuse the same headless transition and command interpreter. Prefer language-neutral export and a training toolchain that respects forge constraints (no committed Python automation); select a concrete supported trainer through a narrow compatibility experiment. A trainer that cannot invoke the shared rules is not eligible; exporting a second simulator would require a separately reviewed contract change.

Build a transparent teacher and baseline, collect demonstrations, correct learner-visited failures, then evaluate self-play against frozen historical versions and varied opponents. Randomize valid arena configurations, substep rates, decision intervals, resource conditions and measured inference delays. Train evaluation-only fixtures before final gameplay rules are closed; do not advertise a final gameplay policy from provisional objectives.

Large teachers/search, wider experiments and distillation are allowed; deploy the smallest qualified student. The operator reports a 20-core Intel i9, 64 GB RAM, 24 GB RTX A5000 training host. Verify available GPU/driver/memory, access and job budget before scheduling work there. Keep resumable checkpoints, dataset/model hashes, seeds, trainer/environment versions and evaluation results so jobs can move between hosts without silently changing rules. Do not install or launch remote jobs during this planning phase.

## Risks / Trade-offs

- Small observations miss board topology -> compare spatial features against scripted trap fixtures and held-out boards.
- Lower cadence becomes unavoidable failure at higher speed -> establish viable opportunity/deadline ranges at maximum boost before tier tuning.
- Ignoring late work still wastes compute -> bound admission and profile in-flight cancellation cost.
- Two simulation implementations drift -> share transitions or require differential replay.
- Large runtime defeats tiny weights -> measure the complete download/memory budget and compare Dart/WASM.
- Survival reward teaches endless circling -> review episode objective and evaluate loops, wins and resource behavior before policy acceptance.
- Platform-specific timing changes strength -> publish supported performance profiles and verify tier ordering empirically on target phones.
- Recreating engine infrastructure wastes effort -> document each custom timing/input/collision helper's gap against installed Flame facilities.

## Migration Plan

1. Keep the construction entry and its responsive tests. Add a separate development gameplay surface only when implementation is requested.
2. Land shared simulation and reviewed controls before model training integration; demonstrate keyboard/touch and baseline opponents.
3. Add the bounded scheduler and injected-delay tests, then benchmark candidate inference backends with identical weights.
4. Train/evaluate offline and publish a versioned candidate bundle only after replay and runtime parity pass.
5. Run phone/browser acceptance tournament; record selected budgets, limitations, and tier profiles before enabling the learned policy outside the development surface.
6. Roll back by disabling the development/learned-policy surface or selecting the previous compatible bundle/baseline; preserve construction entry and invalidate in-flight generations on restart.

## Open Questions

- Exact initial arena dimensions and substep frequency: tune in the slow first-level prototype.
- Best student architecture and inference backend: choose from measured complete-bundle and gameplay results.
- Which physical Android/iOS devices form the supported performance floor: record before accepting numeric budgets.
- First remote training job size and concurrency: choose after trainer compatibility and available fleet capacity checks.

## Reference material

Implementation must inspect installed Flame APIs; upstream links guide reuse rather than requiring newest APIs:

- Flame lifecycle and pause/resume: https://docs.flame-engine.org/latest/flame/game.html
- Flame input facilities: https://docs.flame-engine.org/latest/flame/inputs/inputs.html
- Flame collision limitations (tunneling): https://github.com/flame-engine/flame/blob/main/doc/flame/collision_detection.md
- ONNX lightweight model/WASM guidance: https://onnxruntime.ai/docs/tutorials/web/ep-webgpu.html
- Dart WASM-compatible JS interop: https://dart.dev/interop/js-interop/package-web
- TypeSafe decision interface (inspiration, not a local runtime dependency): https://docs.typesafe.ai/introduction
