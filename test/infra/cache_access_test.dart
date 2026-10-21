import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/forge_probe.dart' as probe;

void main() {
  const path = String.fromEnvironment('ATRAPA_PROBE_DIR');
  test(
    'Host-managed Flutter can read and write the forge cache probe',
    () {
      final dir = Directory(path);
      expect(probe.verifyPayload(dir)['verifiedBytes'], probe.payloadBytes);
      final network = probe.ToyNetwork.fromJson(
        probe.readJson(dir, 'toy-checkpoint.json'),
      );
      expect(network.loss(), lessThan(.01));
      probe.atomicJson(dir, 'flutter-receipt.json', {
        'schema': probe.probeSchema,
        'verifiedBytes': probe.payloadBytes,
        'checkpointEpochs': network.epochs,
        'checkpointLoss': network.loss(),
        'utc': DateTime.now().toUtc().toIso8601String(),
      });
    },
    skip: path.isEmpty
        ? 'Opt-in: pass --dart-define=ATRAPA_PROBE_DIR=absolute-cache-directory'
        : false,
  );
}
