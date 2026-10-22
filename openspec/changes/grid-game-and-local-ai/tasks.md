# Tasks

The accepted review and operator rulings replace the earlier 46-task release plan. This list tracks the first playable slice. Training is owned by macuahuitl; the laptop never trains gameplay weights. Every completion requires the named proof, not merely an artifact existing.

## 1. Shared rules and contracts — Codex

- [x] 1.1 Document installed Flame facilities and keep rules pure Dart. Proof: docs/flame-reuse.md and a package with no Flame/Flutter imports.
- [x] 1.2 Implement validated square-grid profiles, integer substeps, latest boundary turns and deterministic advance. Proof: packages/atrapa_rules/test/rules_test.dart.
- [x] 1.3 Implement 2–4 growing snakes, self/body/wall collision, simultaneous head meetings/swaps and survivor/tick-limit outcomes. Proof: rules_test.dart collision/growth/outcome cases.
- [x] 1.4 Commit a seeded golden replay and shared numeric observation/action schema. Proof: package golden fixture/test and schema documentation in packages/atrapa_rules/README.md.
- [x] 1.5 Implement the reachable-free-space baseline bot. Proof: deterministic safe-choice fixtures in rules_test.dart.

## 2. Playable development app — Codex

- [x] 2.1 Add the flag-gated /play route while preserving construction-only default builds. Proof: test/routes_test.dart and default/dev release web builds.
- [x] 2.2 Render grid and snakes through Flame updates and resize facilities, using shared rules only. Proof: test/play/arena_game_test.dart and app golden replay parity.
- [x] 2.3 Add arrow and bottom portrait touch controls, pause/restart, safe lifecycle handling and 1–3 opponent selection. Proof: test/play/play_screen_test.dart at 320-pixel portrait and desktop.
- [x] 2.4 Add two-human demo WASD/arrow isolation. Proof: keyboard test in play_screen_test.dart.

## 3. Local policy runtime — Codex

- [x] 3.1 Define the versioned bundle contract and defensive loader with checksum, shape/schema and finite-value validation. Proof: docs/policy-bundle.md and test/policy tests covering invalid bundles.
- [x] 3.2 Implement the dense Dart evaluator and synthetic known-weight parity cases without training. Proof: test/policy/local_policy_test.dart.
- [x] 3.3 Connect shared observations and relative actions to the app, with visible baseline/loading/model states. Proof: loading-fallback and decision-adapter tests plus browser inspection.
- [x] 3.4 Record bounded synchronous inference timing and document a reproducible benchmark procedure. Proof: timing log/test and docs/measurements/forge-play.md; physical phone qualification remains separately recorded.

## 4. Compute handoff — macuahuitl

- [ ] 4.1 Generate multi-snake demonstrations and train on the shared rules, then export a compatible policy under assets/policies. Proof: bundle manifest, provenance and host training report including victory-first held-out results per docs/winning-ai.md. Owner: macuahuitl; no laptop training.
- [ ] 4.2 Verify host exported weights against reference observations and integrate the learned opponent. Proof: host reference corpus and app runtime parity within documented FP32 tolerance. Joint handoff; cannot complete with synthetic toy weights.

## 5. Integration — Codex

- [x] 5.1 Run rules tests, app tests/analysis, default/dev web builds, strict OpenSpec validation and managed Wrangler smoke; inspect visible portrait/desktop gameplay and update diagnostics. Proof: docs/measurements/forge-play.md and FORGE_DIAGNOSTICS.md.
- [ ] 5.2 Push work branch and open a reviewable PR into game, reconciling concurrent host changes. Proof: PR URL and passing local checks.

## Workflow follow-up

- A nominated physical phone still needs the 60-second/three-bot decision-time and frame-pacing qualification before calling it supported.
- After the first slice, revisit acceleration/braking resources, versioned helmet/powerups, tiers HARD/HARDER/HARDERER, and trained-policy strength.
- Workers/WASM and live training streams require new evidence-driven changes; their earlier specs are retained in plan/deferred for reference.
- Production deployment, native signing, final art/storyboard and campaign progression are separate work.
