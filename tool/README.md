# Forge infrastructure probe

`forge_probe.dart` exercises storage and CPU checkpointing without downloading a training framework. It uses a tiny 2–8–1 network and synthetic XOR data. It is not a game simulator, gameplay teacher, or candidate Atrapa policy.

Run inside the forge with a fresh, project-owned directory in the existing disk-backed cache:

```sh
ATRAPA_PROBE_DIR=/home/forge/.cache/tillandsias-project/atrapa-training/probes/my-new-run
dart tool/forge_probe.dart write "$ATRAPA_PROBE_DIR"
dart tool/forge_probe.dart read "$ATRAPA_PROBE_DIR"
dart tool/forge_probe.dart train "$ATRAPA_PROBE_DIR"
dart tool/forge_probe.dart resume "$ATRAPA_PROBE_DIR"
flutter test --dart-define=ATRAPA_PROBE_DIR="$ATRAPA_PROBE_DIR" test/infra/cache_access_test.dart
```

The write uses an 8 MiB deterministic payload, flush and same-directory atomic rename. Read verifies every byte in a separate process. Train saves a 6,000-epoch checkpoint; resume runs another 6,000 epochs and compares all weights with a deterministic uninterrupted 12,000-epoch reference. JSON metrics and the host-managed Flutter receipt stay in that run directory. `train` and `write` replace the probe artifacts in the specified directory, so use a fresh directory when preserving an earlier run.

The Flutter cache test is opt-in and skips when no `ATRAPA_PROBE_DIR` compile-time define is supplied. Its explicit invocation tests whether the sibling toolchain sees the same mounted cache. Missing files or incompatible checkpoints fail the test.

Times are narrow smoke measurements, not filesystem throughput or RL training estimates. A flush/rename test does not establish crash/power-loss durability. No inference server or accelerator is used, and no network is needed after tools/dependencies are installed.

The preserved run is `.../probes/session-20261021-a`. To test retention in a later forge session, **read it before overwriting it**, compare hashes with [the evidence report](../plan/experiments/forge-cache-2026-10-21.json), and inspect `flutter-receipt.json`. A surviving process restart proves less than a surviving container recreation. Do not recreate the forge merely to test this while work is active.

Large generated data remains outside Git and `build/web`. Small evidence JSON and probe source are committed. See [FORGE_DIAGNOSTICS.md](../FORGE_DIAGNOSTICS.md) for current limits and observed results.

## Inference-only benchmark

`dart tool/benchmark_rules.dart` evaluates fixed synthetic 252–64–3 parameters and prints aggregated three-bot timing samples. It does not train or supply a gameplay policy. See `docs/measurements/forge-play.md` for browser reproduction and limitations. Actual gameplay training belongs to macuahuitl.
