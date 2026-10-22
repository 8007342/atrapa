# Roadmap

The active implementation is [grid-game-and-local-ai](../openspec/changes/grid-game-and-local-ai/proposal.md), narrowed to the first playable slice by the [accepted review](../openspec/changes/grid-game-and-local-ai/review-2026-10-21.md) and [operator rulings](rulings-2026-10-21.md). Codex owns app/rules evolution; macuahuitl owns gameplay training/retraining. Integration uses work-branch PRs into `game`.

- [ ] Finish local slice checks and merge the shared rules, /play UI, controls and policy runtime through a PR into game.
- [ ] macuahuitl: apply the [victory-first training guidance](../docs/winning-ai.md), with cutoff/enclosure tactics and held-out win/loss/draw evaluation; train against the committed pure-Dart rules/252-input schema and export a compatible bundle plus reference observations/logits; laptops do not train.
- [ ] Integrate and verify the first trained policy when supplied. Until then /play uses an honestly labeled free-space baseline.
- [ ] Nominate a physical mobile floor device and record a 60-second three-bot timing/frame qualification; emulation is development evidence only.
- [ ] After Slice A: versioned acceleration/braking resources, helmet/other powerups, AI cadence tiers HARD/HARDER/HARDERER, campaign/art/storyboard.
- [ ] Revisit asynchronous workers/WASM or a live training viewer only when measured costs or a distinct viewer proposal justify them; earlier drafts live in plan/deferred.
- [ ] Validate native builds/signing and publish an approved production build at atrapa.tlatoani.net as separate work.

Keep [FORGE_DIAGNOSTICS.md](../FORGE_DIAGNOSTICS.md) current. Reuse the existing project cache; no launcher mount override exists. Preserve the cache probe before checking retention in future sessions.
