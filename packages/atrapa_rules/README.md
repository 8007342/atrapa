# Shared Atrapa rules

Pure Dart, with no rendering, asynchronous work or independent clock. Flame calls
`RulesMatch.advance(dt)`; training/replays may call `stepSubstep()` directly.
A tick is one movement substep. Default four substeps per cell at eight substeps
per second means two cells per second. Movement is discrete; hosts interpolate
visually from `head`, `heading` and `substep / substepsPerCell`.

`beforeCellStep` is invoked at the beginning of each new cell interval, before
applying pending turns. Capture all bot decisions from the same state, then queue
them together. A perpendicular input arriving mid-cell waits for the following
interval. Latest perpendicular input wins; same/opposite inputs do not turn.
Boost/braking are deliberately absent from this first playable slice.

Non-growing tails vacate before simultaneous collisions. Growing tails remain.
Projected non-growing tails vacate even when that snake is eliminated; the
remaining dead body stays an obstacle. A sole head is always an occupied head
cell, never a vacating tail. Same target and head swaps
eliminate both snakes. A lone survivor wins immediately, all eliminated is a draw,
and the tick limit is a draw. Growth is per successful cell traversal.

`RulesMatch.fromState` is for fixtures/replays. It copies input state; callers must
provide valid in-bounds nonoverlapping fixtures. Mutable SnakeState fields are
engine-owned during normal play.

Version contracts: `atrapa-rules-v1`, observation `atrapa-grid-v1`, 252 scalar
inputs. See `encodeObservation` documentation for exact channel order. Model
output actions are relative `coast`, `left`, `right`. Rules/schema changes require
new versions, golden replay review, and retraining on the training host.

Validation: `dart pub get`, `dart analyze`, `dart test` in this directory.
The golden test hashes canonical integer snapshots of seed 1724 with four
simultaneous free-space teachers; its FNV-1a digest is `57682a43`.

`MatchReplay` serializes schema, full config/seed, and ordered tick-indexed
commands to JSON. `run()` reconstructs an episode without executing the model.
