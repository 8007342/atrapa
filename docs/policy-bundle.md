# Browser policy bundle contract

Status: runtime contract and synthetic unit fixtures implemented; no trained game
weights are supplied by this forge. The provisional Rust toy teacher export is
not an Atrapa game policy and deliberately does not satisfy this contract.
Macuahuitl owns training and real game bundle delivery.

Bundle paths are `assets/policies/<name>/manifest.json` and `weights.bin`.
Flutter must register each delivered asset directory in pubspec.yaml. Until an
asset exists or if validation fails, the app must visibly retain its deterministic
baseline opponent. The loader returns `PolicyLoadResult` rather than throwing.
No inference service is used; loaded weights are immutable and shared safely.

Minimal manifest (digest below is a placeholder, not a valid bundle):

```json
{
  "format": "atrapa-dense-v1",
  "modelId": "unique-export-and-training-version",
  "numericFormat": "float32-le",
  "normalization": "encoder-owned",
  "output": "logits-argmax-first",
  "rulesSchemaVersion": "atrapa-rules-v1",
  "observationSchema": "atrapa-grid-v1",
  "actions": ["coast", "left", "right"],
  "weightsSha256": "LOWERCASE_SHA256_OF_EXACT_WEIGHTS_BIN_BYTES",
  "layers": [
    {"inputs": 252, "outputs": 64, "activation": "relu"},
    {"inputs": 64, "outputs": 3, "activation": "linear"}
  ]
}
```

For each layer in order, write its dense weight matrix in row-major
`W[output,input]`, followed by its output bias vector. Concatenate the layers;
there is no binary header, padding, transpose, or metadata in weights.bin.
Every parameter is IEEE754 little-endian float32. The Dart evaluator accumulates
in double precision, so parity fixtures must allow an explicit absolute/relative
tolerance against float32 training inference. Hidden activations may be `relu`,
`tanh`, or `linear`. The last layer must be linear logits. Largest logit wins;
exact ties choose the first index. No softmax or sampling is applied.

The runtime rejects nonfinite parameters, unsupported formats, mismatched action
ordering, rules/observation schema mismatches, disconnected shapes, trailing or
missing bytes, more than 16 layers, or more than 100,000 total parameters
(400,000 bytes). Caller supplies expected schemas, expected action ordering, and
expected input length independently of the downloaded manifest. Invalid runtime
observations and overflowing intermediate values throw; the controller must
retain its baseline behavior on evaluation failure as well as loading failure.

The shared `packages/atrapa_rules` encoder owns actual observation semantics;
do not recreate it in Flutter. Current input is 252 values: centered absolute
9x9 spatial cells with three channels (243), heading one-hot (4), normalized speed
(1), and four normalized clear-ray distances (4). Consult the shared encoder for
precise channel ordering and boundary/occupancy conventions. A changed meaning
requires a new observation schema. The loader performs no normalization.

Slice A action indices are 0 coast, 1 relative left, 2 relative right. The caller
converts these through the authoritative controlled snake heading at the same
cell-boundary decision opportunity. Boost/brake require a future negotiated action
schema and compatible rules; adding two outputs silently is incompatible.
Inference is synchronous at scheduled boundary opportunities; it owns no clock,
worker, queue, or game state. Flame remains the lifecycle authority.

Required delivery evidence from the training host: reproducible training/export
identity and seeds; schema versions; held-out tournament results; checksummed
manifest and weights; representative observations with expected logits and
chosen actions; numerical tolerance. Run the same parity corpus in Dart before
marking a bundle ready for gameplay. Browser latency and frame pacing still need
measurement on delivered weights; training speed does not establish runtime cost.
