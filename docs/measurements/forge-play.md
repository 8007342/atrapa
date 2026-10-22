# Playable slice verification — 2026-10-22

Branch: `work/forge-play`, targeting `game`. Tests use Flutter 3.47.7 / Dart 3.13.5 and Flame 1.38.2 in the existing forge toolchain. The baseline opponent is the free-space bot. No gameplay training ran on the laptop and no compatible trained bundle has been supplied.

## Checks

- Rules package tests and analysis: deterministic substeps/turns, growth, self/body/wall collisions, simultaneous heads/swaps, vacating tails including eliminated owners, seeded replay and observation encoding.
- App tests and analysis: 320-pixel portrait layout, keyboard/WASD isolation, pause/restart, long-frame safe pause, terminal pause, asynchronous model readiness without restarting state, flag-gated routes, known synthetic policy outputs, corrupted/schema/shape/nonfinite rejection and loader fallback.
- The committed `golden_episode.json` records 475 commands for four snakes, seed 1724. Rules replay and Flame-adapter replay both finish at tick600, tick-limit draw, matching final bodies and losses. The independent canonical teacher replay digest is `57682a43`.
- Default release web build succeeded. A direct `/play` browser navigation displayed the construction landing screen.
- Development-flagged release build succeeded. `/play` was inspected in visible desktop 1280x720 and Galaxy S24-emulated 360x780 Chromium windows. The operator confirmed seeing snakes playing. Numeric snake identities, grid, touchpad, profile selection, pause/restart, collision outcomes and baseline labels were visible; emulator evidence does not qualify physical phone performance.
- Strict OpenSpec validation passes after applying the accepted review/rulings and retaining deferred scope outside active specs.
- The existing Wrangler-managed preview serves the flagged build. Its route is https://www.atrapa.localhost:18443/play . No Cloudflare production deployment was performed.

Commands:

```sh
flutter analyze
flutter test
# Optional existing-cache verification remains opt-in:
flutter test --dart-define=ATRAPA_PROBE_DIR=/home/forge/.cache/tillandsias-project/atrapa-training/probes/session-20261021-a test/infra/cache_access_test.dart
flutter build web --release --no-web-resources-cdn
flutter build web --release --no-web-resources-cdn --dart-define=ATRAPA_DEV_PLAY=true
openspec validate --all --strict
```

In `packages/atrapa_rules`: `dart analyze`, `dart test`, and `dart run bin/replay.dart test/fixtures/golden_episode.json`.

## Synthetic runtime measurement

`tool/benchmark_rules.dart` constructs fixed synthetic parameters and evaluates a 252–64–3 network (16,387 parameters, 65,548 weight bytes). It never updates weights or claims to be a gameplay opponent. Each measurement window averages ten three-bot batches to reduce coarse browser timer artifacts; 300 windows follow 30 warmup passes.

| Environment | Three-forward-pass batch p50 | p95 | Max window-average batch |
|---|---:|---:|---:|
| Forge Dart VM | 69.9 us | 115.4 us | 131.4 us |
| Host-managed headless Chromium 156 | 40 us | 50 us | 100 us |

Raw results: `synthetic-policy-vm.json` and `synthetic-policy-chromium.json`. The browser user agent is a preset and must not be read as evidence the actual laptop host is Windows. Timings cover synthetic forward passes only, not observation encoding, bot search, rendering, asset loading, or a trained model's playing quality. The earlier unaggregated browser test returned zero-microsecond p50 due to timer granularity; use aggregated windows, not a claim of zero work.

Reproduce VM and browser-compiled code:

```sh
dart tool/benchmark_rules.dart
dart compile js tool/benchmark_rules.dart -o build/web/benchmark.js
```

With a development build already served locally, inject `/benchmark.js` into a separate test browser page and read the JSON console entry. The benchmark artifact is generated, ignored with build/, and not included in committed game assets. Remove it or rebuild before packaging a public artifact. It is not needed for normal play.

The app also records bounded windows of all-bot boundary decision cost and logs p95 microseconds. Loaded-policy calls separately report per-decision samples. The initial investigation budget is 2ms for all bot work at a boundary; this synthetic measurement only supports trying synchronous Dart first.

## Remaining acceptance and handoff

- Macuahuitl must train on `packages/atrapa_rules` with `atrapa-rules-v1`, `atrapa-grid-v1`, 252 inputs and coast/left/right outputs. Deliver assets and representative expected logits/actions according to `docs/policy-bundle.md`; no toy-grid weights will be substituted.
- A real floor phone must be named, then run the delivered policy in a 60-second, three-bot match and record cold load, all-bot p95 decision cost and frame pacing. No phone certification is claimed here.
- Creating the required PR through the connected GitHub tool returned HTTP403 `Resource not accessible by integration`. `gh` is installed but has no forge credentials by design. Branch push through the mirror succeeded. No direct push to game/main or credential workaround was attempted. PR body is saved in `plan/forge-play-pr.md`; use the compare link to open it on an authorized host.
