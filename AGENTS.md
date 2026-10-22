# Atrapa agent guidance

- Keep `FORGE_DIAGNOSTICS.md` current as sessions discover or resolve forge issues, verify capabilities, or measure infrastructure limits. Record dated evidence, workarounds, and remaining needs; distinguish observed results from host reports and proposals. Preserve resolved incident history and never include secrets.
- Reuse Flame's lifecycle, timing, input, rendering and component facilities where appropriate. Custom grid/domain rules must not introduce an independent running game clock.
- Read the active OpenSpec change and `plan/roadmap.md` before gameplay/training work. Keep planning status separate from implemented behavior.
- Before rerunning cache experiments in a later forge session, verify the preserved `session-20261021-a` probe and hashes using `tool/README.md`; record whether artifacts survived, and do not overwrite the evidence before checking. The launcher has no mount override; use the existing project cache for bounded experiments.

- `plan/rulings-2026-10-21.md` overrides older planning text. Rules live in `packages/atrapa_rules`; the app and trainer import them. Never reimplement rules in `lib/`. Rules/schema changes require version and golden replay updates, then retraining on macuahuitl.
- Actual gameplay training is compute-host work; do not train on this laptop. The Dart XOR and Rust toy-grid probes are infrastructure evidence only.
- Use `work/<topic>` branches and PRs into `game`; do not push app changes directly to main or game. Default production builds keep `/play` disabled; development preview builds enable `ATRAPA_DEV_PLAY`.
