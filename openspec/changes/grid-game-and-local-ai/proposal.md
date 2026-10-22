# Proposal

## Why

Build a small playable Atrapa slice before expanding the campaign or inference infrastructure. Use the exact same pure-Dart grid rules in the browser and macuahuitl's trainer so exported opponents play the game they learned.

## What Changes

- Implement shared square-grid rules, four substeps per cell by default, latest-press boundary turns, growth, self/body/wall collisions, simultaneous head-on losses and tick-limited matches.
- Add a compile-time-enabled `/play` development surface with one human versus 1–3 AI snakes and a two-human WASD/arrow demo, retaining the construction entry.
- Use the operator's reachable-free-space heuristic as the baseline/teacher. Run synchronous decisions from a common pre-move snapshot at cell boundaries.
- Load versioned local dense-policy bundles with a Dart evaluator, explicit baseline fallback and measured forward-pass cost.
- Keep training and retraining on macuahuitl; the laptop forge tests exported weights without training them.
- Defer resources, powerups (including helmet), cadence tiers, workers/WASM, training feed/viewer and fleet APIs until after this slice as directed by the accepted review. Preserve those ideas in the roadmap.

## Capabilities

### New Capabilities

- `grid-gameplay`: Shared deterministic grid state, growing snakes, collision outcomes, baseline opponents and local controls.
- `local-policy-inference`: Numeric policy contract, integrity validation, synchronous Dart evaluation and explicit fallback.
- `offline-policy-training`: Shared rules import, reproducible exports and training/runtime parity across the compute handoff.

### Modified Capabilities

- `atrapa`: Development-only play route and Flame adapter, preserving the public construction screen.

## Impact

Adds `packages/atrapa_rules` and app play/policy modules, tests and documentation. The app consumes the rules package by path. Training runs from a normal checkout on the operator's macuahuitl workstation; no remote job API is needed for Slice A. Work branches merge through PRs into `game`. Rules/schema evolution belongs to Codex; a version bump plus updated golden replay signals macuahuitl to retrain. No production Cloudflare deployment or native signing is part of this slice.
