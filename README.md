# Atrapa

Atrapa, de Tlatoāni, homenaje al antiguo Atrapa, de Bulloncito.

A Flutter + Flame game for web, Android, iOS, Linux, macOS, and Windows. The first screen is an Under Construction landing page; gameplay is still to be specified.

## Development

Install the Flutter stable SDK and Node.js 22 or newer, then:

```sh
flutter pub get
npm ci
flutter run -d chrome
```

Native builds require the corresponding platform SDK and host operating system. The generated mobile application ID is `net.tlatoani.atrapa`.

## Local Cloudflare preview

```sh
npm run dev
```

This builds Flutter's release web bundle and serves it with Wrangler. After editing Dart, rebuild with `npm run build`. To serve an existing build, use `npm run preview`.

## Validation

```sh
flutter analyze
flutter test
flutter build web --release
openspec validate --all --strict
```

## Cloudflare publication

The intended production address is https://atrapa.tlatoani.net. `wrangler.jsonc` configures a Workers static-assets site with SPA routing and that custom domain, following [Cloudflare's static assets configuration](https://developers.cloudflare.com/workers/static-assets/).

When ready to publish, authenticate Wrangler to the Cloudflare account managing `tlatoani.net`, then run `npm run deploy`. This creates a production deployment and connects the custom domain. Local preview does not publish to Cloudflare.

## Project structure

- `lib/main.dart`: responsive construction screen.
- `lib/game/atrapa_game.dart`: decorative [Flame](https://docs.flame-engine.org/latest/index.html) canvas, ready for future game components.
- `openspec/specs/`: behavior requirements; update these before implementing future features.
- `plan/roadmap.md`: outstanding work across sessions.
- `FORGE_DIAGNOSTICS.md`: observed forge behavior, Podman storage guidance, and the training-host wishlist.
- Platform directories: Flutter runners for each supported target.

The root `LICENSE` governs this project.
