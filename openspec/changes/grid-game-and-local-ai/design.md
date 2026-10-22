# Design

## Context

This design applies the accepted review in `review-2026-10-21.md` and overriding `plan/rulings-2026-10-21.md`, including the later work split. Those decisions replace the earlier speculative release plan. The baseline repository has a decorative Flame landing screen; this change adds the playable slice. Macuahuitl owns actual training/export. The laptop must not train gameplay weights.

## Goals / Non-Goals

**Goals:** A playable development browser route using one authoritative Dart rules engine; human controls and 2–4 growing snakes; a strong deterministic baseline; safe loading of compatible local trained policies; repeatable tests and measured evaluation cost.

**Non-Goals:** Production launch, final artwork/story, resource boost/braking, helmet/other powerups, cadence difficulty tiers, WASM or worker infrastructure, remote training viewer, fleet orchestration, and certification on untested phones. These are explicitly post-slice per the accepted review.

## Decisions

### One shared pure-Dart transition

`packages/atrapa_rules` has no Flame/Flutter imports. It owns configuration, heading interpretation, queued turns, substep progression, collision resolution, growth, deterministic tie-breaking, observation encoding and replay state. The app imports it by path; macuahuitl's trainer must use the same package. No second simulator in `lib/` or another language.

Default development tuning: 16x16 arena, four substeps per cell, eight substeps per simulation second, initial body length three, growth every six cell movements, and 2,400 substep tick limit. Values are tunable profiles, not promises of a final campaign. Profile validation also covers 3 and 5 substeps per cell. At each cell opportunity, collect all AI choices from the same state before queueing them. The latest human perpendicular press replaces the pending turn; one is consumed per boundary. Same/opposite headings are recognized without reversing; Slice A leaves speed constant for everyone.

All move intents resolve together. Walls and body occupancy, including own body, kill; contested head destinations and head swaps kill both. Non-growing tails vacate on a move; growing tails stay. Dead bodies remain obstacles for the rest of the match. One survivor wins; zero survivors or tick limit is a draw. These documented occupancy details are deterministic defaults exercised by tests and require a schema/golden change if modified.

### Flame owns local time and presentation

`ArenaGame.update(dt)` advances shared rules; no independent clock or custom timer framework. A long frame is bounded by pausing the local development game instead of teleporting through unchecked cells. Background lifecycle pauses; resume requires a user action. `GameWidget` and Flame's resize/render lifecycle project grid state. Logical positions never depend on viewport pixels. See `docs/flame-reuse.md` for installed API evidence.

A compact dark grid renderer draws bodies, headings and numeric snake identities. Portrait controls sit below the arena. Solo uses arrows/touch; two-human demo uses WASD for snake1, arrows for snake2. Pause/restart and profile changes reset only the local match. Keyboard repeat cannot queue repeated turns. A single Focus adapter feeds the authoritative interpreter. No UI invents collision or growth rules.

### Development route boundary

`ATRAPA_DEV_PLAY` defaults false. Default builds expose construction only; explicitly enabled builds allow `/play` with Flutter's path URL strategy and Wrangler SPA fallback. Route tests exercise enabled and disabled behavior. `npm run build` remains the production-safe build; the development preview build passes the flag. Actual live training viewing remains a separate later change; any local exhibition is labeled as such.

### Synchronous Dart inference first

The runtime consumes the shared `atrapa-grid-v1` observation (252 values) and `coast,left,right` action ordering. The review's proposed 9x9x3 + heading4 + speed1 + rays4 arithmetic is 252, not 256. The core documents absolute axes, blocked/head/free channels, heading order, speed normalization and rays. Rules schema `atrapa-rules-v1` is recorded in every accepted bundle. No screenshot or text encoding is required.

The loader checks format, schema versions, dimensions, action ordering, finite parameters and SHA256 of little-endian float32 weights before activation. Output is finite logits with deterministic first-max argmax; these are not calibrated probabilities. Caps bound model file and parameter work. The evaluator owns no game state. Policy failure or absent weights leaves an honestly labeled free-space baseline. Asset manifests and loading paths are documented in `docs/policy-bundle.md` for the compute host.

Forward passes run synchronously at cell boundaries. A bounded sample window records microseconds per decision. Initial investigation threshold is 2 ms all-bot decision work at a boundary; a real phone floor device is still to be nominated. Desktop/emulation measurements cannot qualify a physical device. Only if measured work fails the selected budget should an asynchronous/WASM change be proposed. No worker deadlines, queues or stale-result machinery is needed in this slice.

### Offline compute handoff

Actual teacher-data generation, learning and retraining run on macuahuitl using the shared rules. Codex provides the rules/schema contract and tests, browser evaluator and bundle parity checks; no laptop training jobs are run. The earlier Rust toy-grid and Dart XOR probes are infrastructure demonstrations, not gameplay models. A host export must match the committed contract and include parity fixtures before it is called compatible. No default trained bundle is fabricated when the host has not supplied one.

Golden replay is checked in the rules package and exercised by the app test environment. A rules/schema change updates its version and golden; macuahuitl then retrains. Integration through `work/<topic>` PRs into `game` keeps both hosts on the same source.

## Risks / Trade-offs

- Model exports may arrive later or with another schema -> keep baseline available; reject mismatches and document the exact handoff.
- Tiny models may choose immediate death -> authoritative rules still apply; baseline and learned model labels remain distinct, and strength needs a host tournament.
- Fast-frame catch-up could skip bot opportunities -> use shared before-cell callback inside advancement and test frame partition equivalence.
- Prototype constant speed omits planned resources -> make that scope clear; defer related powerups and action dimensions together until a versioned rules change.
- Main and game diverged during parallel work -> merge the cache evidence carefully, preserving both host diagnostics and the operator's no-mount-override correction.

## Migration Plan

1. Land rules and replay tests, UI and safe policy runtime together on a work branch.
2. Verify tests, analysis, strict OpenSpec validation and default/development web builds.
3. Serve the flagged build through managed Wrangler and inspect portrait, desktop and keyboard play.
4. Open a PR into `game`, preserving host review/rulings. Merge only after checks and branch policy allow.
5. When compatible host weights arrive, verify their fixtures and browser behavior; until then report baseline-only readiness.
6. Roll back by disabling the dev flag or selecting the baseline; public construction remains the default.

## Open Questions

- Which physical Android/iOS device should qualify the first mobile performance budget? This does not block emulator-based development and tests.
- Which host-exported model will be the first default compatible bundle? Actual training remains assigned to macuahuitl.
