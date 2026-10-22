# Atrapa

Atrapa, de Tlatoāni, homenaje al antiguo Atrapa, de Bulloncito.

A Flutter + Flame game for web, Android, iOS, Linux, macOS, and Windows. The public entry is an Under Construction landing page. A flag-gated /play development surface uses a shared pure-Dart rules engine and free-space baseline opponents. Learned opponents require a compatible export from macuahuitl.

## Development

Install the Flutter stable SDK and Node.js 22 or newer, then:

```sh
flutter pub get
npm ci
flutter run -d chrome --dart-define=ATRAPA_DEV_PLAY=true
```

Native builds require the corresponding platform SDK and host operating system. The generated mobile application ID is `net.tlatoani.atrapa`.

## Local Cloudflare preview

```sh
npm run dev
```

This builds Flutter's development-enabled release web bundle and serves it with Wrangler. Open `/play` for the prototype. After editing Dart, rebuild with `npm run build:dev`. `npm run build` creates the production-safe construction build with play disabled. To serve an existing build, use `npm run preview`.

## Play controls

Arrow keys or the bottom touchpad steer. Turns apply at cell boundaries; latest press wins. This first slice uses constant speed with growing bodies, self-collision and a tick-limit draw. Choose 1–3 AI opponents or a two-human demo (WASD for player one, arrows for player two). Space pauses; Restart creates a fresh match.

Rules and golden replay: `packages/atrapa_rules/README.md`. The training host exports bundles according to `docs/policy-bundle.md`; without a compatible bundle, the app labels and uses the baseline. Actual training never runs on this laptop.

## Validation

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter build web --release --no-web-resources-cdn --dart-define=ATRAPA_DEV_PLAY=true
openspec validate --all --strict
```

Run `dart test` in `packages/atrapa_rules` for headless rules/golden tests. Replay the committed episode there with `dart run bin/replay.dart test/fixtures/golden_episode.json`.

## Cloudflare publication

The intended production address is https://atrapa.tlatoani.net. `wrangler.jsonc` configures a Workers static-assets site with SPA routing and that custom domain, following [Cloudflare's static assets configuration](https://developers.cloudflare.com/workers/static-assets/).

When ready to publish, authenticate Wrangler to the Cloudflare account managing `tlatoani.net`, then run `npm run deploy`. This creates a production deployment and connects the custom domain. Local preview does not publish to Cloudflare.

## Project structure

- `lib/main.dart`: responsive construction screen.
- `lib/play/`: Flame play adapter, responsive controls and match presentation.
- `packages/atrapa_rules/`: pure shared simulation, baseline, observation schema and replay.
- `lib/policy/`: defensive local model loading and dense evaluator.
- `lib/game/atrapa_game.dart`: decorative [Flame](https://docs.flame-engine.org/latest/index.html) canvas, ready for future game components.
- `openspec/specs/`: behavior requirements; update these before implementing future features.
- `plan/roadmap.md`: outstanding work across sessions.
- `FORGE_DIAGNOSTICS.md`: observed forge behavior, Podman storage guidance, and the training-host wishlist.
- Platform directories: Flutter runners for each supported target.

The root `LICENSE` governs this project.
