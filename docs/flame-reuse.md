# Flame reuse in the playable slice

Inspected installed Flame 1.38.2 source under the forge pub cache. The app imports Flame through its pinned Flutter dependency; pure `packages/atrapa_rules` imports neither Flame nor Flutter.

| Facility | Existing API/source | Atrapa use |
|---|---|---|
| Update delta and game loop | `FlameGame.update(double dt)`, `src/game/flame_game.dart` | ArenaGame supplies accepted elapsed time to the shared rules transition; no independent ticker |
| Pause/resume | `pauseEngine`, `resumeEngine` on Game | Manual pause and background lifecycle stop the engine |
| Component ownership and rendering | FlameGame/GameWidget lifecycle and canvas rendering | GameWidget owns arena rendering; replacing a match creates a new game identity |
| Timed effects | `TimerComponent`, `src/components/timer_component.dart` | Available for future presentation effects; no generic replacement timer framework |
| Input | Flutter Focus key events and IconButton pointer semantics alongside GameWidget; Flame keyboard handlers available | One input adapter submits directions to the shared rules interpreter; no parallel input event pump |
| Resize | Flame `onGameResize`/game size and Flutter layout constraints | Project logical square grid into available pixels; resizing does not alter cells or simulation |
| Collision helpers | Flame collision hitboxes | Not used to redefine logical grid occupancy: the shared transition resolves exact cell intents and head swaps for both training and app |

The custom step accumulator, cell boundaries, growth and collision resolution are game-domain rules in `atrapa_rules`. They consume explicit elapsed time and do not run a timer themselves. The offline trainer invokes these same methods without rendering. Grid collision logic is necessary because frame-overlap collision callbacks alone can tunnel and cannot define headless training behavior.

The accepted Slice A uses constant-speed profiles. Resource acceleration/braking, powerups, asynchronous inference workers and live training feeds remain later changes per the accepted review. Their future implementation must reuse these lifecycle facilities and bump the shared rules/observation contracts when behavior changes.
