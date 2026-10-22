# Local policy assets

`default/` is the first trained game policy (`freespace-v1`), delivered by
macuahuitl with `packages/atrapa_train` against `atrapa-rules-v1` /
`atrapa-grid-v1`. It has `manifest.json` and `weights.bin` per
[the delivery contract](../../docs/policy-bundle.md), and `parity.json`
(observations, logits and actions; tolerance 1e-5), which
`packages/atrapa_train` tests run through the app's `LocalPolicy`.
Retrain whenever the rules or observation schema version changes.
