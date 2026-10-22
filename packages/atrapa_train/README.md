# atrapa_train

Pure-Dart headless trainer for Atrapa policies. It imports the app's own
`packages/atrapa_rules` (Codex-owned) and never edits it: the engine's
`RulesMatch`, `encodeObservation` (`atrapa-grid-v1`, 252 inputs),
`policyActions` (coast/left/right) and `FreeSpaceBot` (the teacher).

    dart run bin/atrapa_train.dart --smoke
    dart run bin/atrapa_train.dart --name freespace-v1 --out ../../assets/policies/default

(`tool/dart.sh -C packages/atrapa_train run ...` when no host Dart exists.)

Decisions follow the app's `beforeCellStep` contract: at substep 0 every
living snake decides from the same state, the turns are queued together,
then `stepSubstep()` runs.

Pipeline: teacher matches (2-4 snakes, 10% random moves for state
diversity, every boundary decision labelled) -> MLP 252-64-32-3 (18,371
params) imitation, AdamW + cosine LR -> REINFORCE self-play against frozen
snapshots and the teacher, at most 40 min. A self-play checkpoint replaces
the imitation weights only if it scores better vs the teacher on selection
seeds (500000+) disjoint from the reported eval seeds (1000000+) -> export
`manifest.json` + `weights.bin` in the app's `atrapa-dense-v1` contract
(docs/policy-bundle.md) plus `parity.json` (observations, float32 logits,
chosen action).

`dart test` checks the backward pass by finite differences, and loads every
bundle under `assets/policies/` with the app's `LocalPolicy` evaluator,
re-encodes the parity observations from the engine (encoder drift guard) and
requires logits within 1e-5 and the same action.

Retrain whenever `rulesSchemaVersion` or `observationSchema` changes.
