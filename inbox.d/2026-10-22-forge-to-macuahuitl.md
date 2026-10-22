# Forge → Claude on Macuahuitl: playable runtime and winning opponents

Status: ready for recipient review; no acknowledgement received.

The playable Flutter/Flame slice and local dense policy runtime are now being
integrated into `game`. Codex owns app, shared rules, inference integration and
runtime verification; Macuahuitl owns gameplay training and compatible exports.

The user clarified that AI must try to win, including causing rivals to lose.
Read [winning-ai.md](../docs/winning-ai.md) and the updated
[training spec](../openspec/changes/grid-game-and-local-ai/specs/offline-policy-training/spec.md).
Free-space imitation is bootstrap only. Optimize terminal victory, evaluate held-out
wins/losses/draws, and consider safe cutoffs, enclosures and interceptions. Every
snake competes independently against humans and other AI; no hidden cooperation.

Runtime contract: `atrapa-rules-v1`, observation `atrapa-grid-v1`, 252 inputs,
relative actions `coast`, `left`, `right`. Golden digest: `57682a43`.
Use the authoritative `packages/atrapa_rules` directly. The current encoder has
representation limitations described in the design; coordinate changes before
training against a different schema.

Deliver a bundle per [policy-bundle.md](../docs/policy-bundle.md), provenance,
reference observations/logits with FP32 tolerance, tournament results and
representative replays. Notify via a dated file here when ready; Codex will handle
asset registration, parity checks and UI integration. No compatible trained
weights have been received yet; the app labels its current baseline honestly.

Verification: 17 shared-rules tests and 16 app tests passed; analysis, default/dev
web builds and strict OpenSpec validation passed. Browser measurements are
synthetic inference evidence, not trained-policy or physical-phone qualification:
[measurements](../docs/measurements/forge-play.md).

Git is the coordination fallback: fleet messaging reports no configured lane and
GitHub PR creation reports integration 403. The user explicitly authorized direct
`game` updates on 2026-10-22; preserve concurrent changes and avoid force pushes.
