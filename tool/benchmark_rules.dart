// Deterministic synthetic inference benchmark. No learning or gameplay weights.
import 'dart:convert';
import 'dart:typed_data';

import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:crypto/crypto.dart';

import 'package:atrapa/policy/local_policy.dart';

void main() {
  const count = 252 * 64 + 64 + 64 * 3 + 3;
  final data = ByteData(count * 4);
  for (var i = 0; i < count; i++) {
    data.setFloat32(i * 4, ((i % 17) - 8) * .001, Endian.little);
  }
  final bytes = data.buffer.asUint8List();
  final policy = LocalPolicy.fromBundle(
    {
      'format': 'atrapa-dense-v1',
      'modelId': 'synthetic-benchmark-not-trained',
      'numericFormat': 'float32-le',
      'normalization': 'encoder-owned',
      'output': 'logits-argmax-first',
      'rulesSchemaVersion': rulesSchemaVersion,
      'observationSchema': observationSchema,
      'actions': policyActions,
      'weightsSha256': sha256.convert(bytes).toString(),
      'layers': [
        {'inputs': 252, 'outputs': 64, 'activation': 'relu'},
        {'inputs': 64, 'outputs': 3, 'activation': 'linear'},
      ],
    },
    bytes,
    expectedObservationSchema: observationSchema,
    expectedActions: policyActions,
    expectedRulesSchemaVersion: rulesSchemaVersion,
    expectedInputSize: observationSize,
  );
  final match = RulesMatch(MatchConfig(snakeCount: 4));
  final inputs = [for (var id = 1; id < 4; id++) encodeObservation(match, id)];
  for (var i = 0; i < 30; i++) {
    policy.evaluate(inputs[i % 3]);
  }
  final batches = <double>[];
  final actions = <String>[];
  for (var batch = 0; batch < 300; batch++) {
    final watch = Stopwatch()..start();
    for (var repeat = 0; repeat < 10; repeat++) {
      for (final input in inputs) {
        final action = policy.evaluate(input).actionId;
        if (actions.length < 3) actions.add(action);
      }
    }
    batches.add(watch.elapsedMicroseconds / 10);
  }
  batches.sort();
  // Standalone VM/browser benchmark emits one machine-readable JSON record.
  // ignore: avoid_print
  print(
    jsonEncode({
      'kind': 'synthetic synchronous Dart evaluator, not training or gameplay strength',
      'architecture': '252-64-3',
      'parameters': count,
      'weightBytes': bytes.length,
      'warmupPasses': 30,
      'measurementWindows': 300,
      'batchesPerWindow': 10,
      'botsPerBatch': 3,
      'p50BatchMicros': batches[149],
      'p95BatchMicros': batches[284],
      'maxBatchMicros': batches.last,
      'actionSample': actions.take(3).toList(),
      'rulesSchema': rulesSchemaVersion,
      'observationSchema': observationSchema,
    }),
  );
}
