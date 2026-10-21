# Tasks

These tasks describe future implementation, not work completed by writing this plan. Groups are dependency ordered; reviewed gameplay semantics gate their dependent tasks, while runtime benchmarks can use explicitly provisional fixtures. Art and storyboard remain separate work.

## 1. Shared contracts and Flame reuse

- [ ] 1.1 Inventory the installed Flame update, timer, lifecycle, input, camera/resize, and collision facilities; deliver a reuse map naming each custom domain helper and the engine gap it fills, with installed API references.
- [ ] 1.2 Review tap/hold/repeat, held-direction-after-turn, release, boundary command replacement, and resource recovery semantics with the user; update the gameplay contract and table-driven command examples before implementing group 3 or generating demonstrations.
- [ ] 1.3 Review simultaneous head collisions/head swaps, body occupancy and self-collision/growth scope, episode completion, and powerup extension/stacking/expiry semantics; record decisions and example outcomes before dependent collision/effect implementations or final training.
- [ ] 1.4 Define versioned level and opponent profiles separating cells, substeps per cell, substeps per simulation second, speed limits, resources and decision opportunities; verify units/schema with valid and invalid profile fixtures, including 3, 4, and 5 substeps per cell.

## 2. Shared simulation and lifecycle

- [ ] 2.1 Implement the reusable headless grid transition driven by explicit elapsed simulation time and seeds; verify each configured substep count crosses exactly one cell and seeded replay reproduces states.
- [ ] 2.2 Adapt the transition to Flame update/pause/resume and existing timer facilities; verify equal accepted simulation time with varied frame partitions yields equivalent state and pausing spends no gameplay time.
- [ ] 2.3 Implement ordered boundary traversal, simultaneous intent collection and reviewed collision resolution after 1.3; verify walls, other-snake contact, contested cells/head swaps, and large-delta traversal cannot tunnel.
- [ ] 2.4 Add bounded catch-up/background-resume handling and generation invalidation; verify a long frame/background interval causes documented pause/overload behavior without skipping collisions or applying pre-pause decisions.
- [ ] 2.5 Document headless advance, replay format, and the Flame timing adapter; verify a documented replay runs without rendering or a wall-clock loop.

## 3. Controls, resources, and development play surface

- [ ] 3.1 Implement the reviewed shared command interpreter after 1.2; verify keyboard, touch and bot commands produce identical authoritative outcomes, with one boundary turn at most and no repeated-turn burst.
- [ ] 3.2 Add keyboard arrow handling and a bottom directional touchpad using existing Flame/Flutter input facilities; verify key repeat/release, touch cancellation, focus loss and portrait viewport usability against the reviewed command examples.
- [ ] 3.3 Implement acceleration, costly finite braking, positive speed floor, caps and resource accounting; verify exhaustion, minimum/maximum speeds and equal consumption across frame and inference schedules.
- [ ] 3.4 Implement reviewed temporary powerup behavior after 1.3 using existing timer/effect facilities where suitable; verify benefit, expiry, stacking rules and pause/resume equivalence headlessly and in the play surface.
- [ ] 3.5 Add the development gameplay surface and square-grid projection without replacing the construction entry; verify existing landing tests, logical-state preservation on resize, and keyboard/touch play at 320-pixel portrait and desktop widths.
- [ ] 3.6 Configure a slow small-arena first-level profile and faster development level profiles; document their measured units and demonstrate that level speed changes independently of HARD/HARDER/HARDERER selection.

## 4. Baseline opponents and bounded scheduling

- [ ] 4.1 Build a deterministic scripted baseline opponent obeying the shared command rules; verify replay repeatability and representative obstacle/resource fixtures, and document its use during inference unavailability.
- [ ] 4.2 Implement latest-value broadcast and bounded pending inference admission with reliable outcome delivery and lifecycle cleanup; stress with slow/missing subscribers and verify bounded queues, no lost match outcomes and no blocked simulation.
- [ ] 4.3 Implement deadline-tagged snapshots/results, shared-snapshot opportunities and intended-boundary application; verify out-of-order completion, changed heading, agent death, restart and expired results cannot mutate the wrong state.
- [ ] 4.4 Add worker failure supervision, bounded retries and documented continuation/fallback behavior; verify injected hangs/failures do not trigger retry storms, repeated turns or extra resource spending.
- [ ] 4.5 Configure independent tier schedules and expose deadline misses, replacement counts, stale rejections and wasted compute metrics; inject delay/load and verify supported bounds are reported without hidden tier relabeling.
- [ ] 4.6 Document the actor/message delivery contract and scheduler instrumentation; verify examples cover a successful decision, a late discarded result, a failed worker and match disposal.

## 5. Policy format and inference comparison

- [ ] 5.1 Freeze an initial numeric observation/action schema with geometry representation, masks, visibility, normalization, heading context and decision interval; verify encoder fixtures and equal human/bot authority after reviewed control decisions.
- [ ] 5.2 Add bundle manifests and integrity/compatibility validation; verify wrong hashes, shape/schema mismatches, corrupted files and unsupported runtime requirements select the documented fallback visibly.
- [ ] 5.3 Implement a minimal dense-policy Dart evaluator and fixed known-weight fixtures; verify output arithmetic against a reference observation corpus with recorded tolerances and action agreement.
- [ ] 5.4 Implement an isolated browser WASM inference candidate with the same fixtures, a persistent bounded worker and matching assets; verify output parity, readiness/warmup states and no main-loop wait or server inference calls.
- [ ] 5.5 Benchmark both candidates on declared browsers/devices for cold/warm startup, total asset transfer/unpacked size, memory, p50/p95 latency, frames, deadline misses and sustained all-bot load; deliver reproducible measurements and a runtime selection record.
- [ ] 5.6 Integrate the selected backend with shared weights and separate agent state; verify reset isolation, readiness failure fallback and multiple-opponent correctness using identical replay fixtures.
- [ ] 5.7 Add only the selected runtime's required Wrangler asset/cache/isolation configuration; verify local preview serves matching assets, loaded inference works without network, any claimed offline reload works, and no production deployment occurs as part of validation.
- [ ] 5.8 Document supported runtime/device profiles and selected size/performance thresholds before candidate acceptance; verify each threshold is traceable to recorded benchmark evidence rather than a desktop training claim.

## 6. Offline learning and portable jobs

- [ ] 6.1 Select a compatible offline training framework/toolchain respecting repository automation constraints; deliver a smoke experiment that consumes the shared headless transition and exports a policy without duplicating game rules.
- [ ] 6.2 Implement demonstration collection from the scripted teacher and a versioned dataset/replay manifest; verify fixed-seed reproduction, held-out separation and complete rules/schema provenance.
- [ ] 6.3 Train the first small feedforward student by imitation and collect teacher corrections on learner-visited failure states; deliver checkpoints and baseline comparisons with measured parameter count and complete bundle size.
- [ ] 6.4 Add self-play against a pool of frozen historical and scripted opponents, with varied speed/resource/cadence/delay conditions; verify opponent sampling, per-agent state isolation and episode replay records.
- [ ] 6.5 Add resumable job packaging and optional fleet execution instructions; verify checkpoint resume locally and record actual remote host access, GPU memory and operational allocation before launching any remote experiment.
- [ ] 6.6 Compare student sizes, optional larger teachers/distillation and precision variants; verify each exported candidate passes numerical/action parity and carries training configuration, seeds, artifact hashes and provenance.
- [ ] 6.7 Document training and export commands, datasets, compute usage and limitations; verify a clean environment can reproduce the smoke experiment and evaluate an existing checkpoint.

## 7. Acceptance tournament and integration

- [ ] 7.1 Freeze held-out maps, seeds, opponents, schedule combinations, sample counts and quality thresholds before final selection; verify training/tuning manifests exclude the held-out acceptance set.
- [ ] 7.2 Run candidate tournaments after the gameplay review gates are closed; report wins/outcomes, survival, collisions, looping, resource use and uncertainty against the baseline and historical opponents across level speeds.
- [ ] 7.3 Validate HARD/HARDER/HARDERER ordering and viable decision margins through maximum configured boost with sustained multi-opponent load; document failures and retune or reject profiles that miss acceptance bounds.
- [ ] 7.4 Run real Android and iOS browser sessions plus desktop integration checks with keyboard and portrait touch controls; verify local inference, responsiveness and declared complete-bundle/runtime limits, recording unsupported profiles honestly.
- [ ] 7.5 Run Flutter analysis/tests, release web build, OpenSpec strict validation and the documented Wrangler smoke flow; verify the construction entry, development game, bundle rollback and baseline recovery together.

## Workflow follow-up

- Review the proposal and semantic gates before applying dependent implementation tasks.
- Archive only after implementation and acceptance are complete; retain unresolved art/storyboard/campaign work as separate proposals.
- Production Cloudflare publication and native signing/build acceptance remain separate operational work.
