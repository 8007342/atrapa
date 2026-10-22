import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:atrapa/policy/local_policy.dart';
import 'package:atrapa/policy/policy_loader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List encode(List<double> values) {
    final data = ByteData(values.length * 4);
    for (var i = 0; i < values.length; i++) {
      data.setFloat32(i * 4, values[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }

  final values = <double>[1, 2, -1, 3, .5, -1];
  Map<String, dynamic> manifest(Uint8List weights) => {
    'format': 'atrapa-dense-v1',
    'modelId': 'synthetic-fixture',
    'numericFormat': 'float32-le',
    'normalization': 'encoder-owned',
    'output': 'logits-argmax-first',
    'rulesSchemaVersion': 'test-rules-v1',
    'observationSchema': 'test-vector-v1',
    'actions': ['coast', 'left'],
    'weightsSha256': sha256.convert(weights).toString(),
    'layers': [
      {'inputs': 2, 'outputs': 2, 'activation': 'linear'},
    ],
  };
  LocalPolicy load(Map<String, dynamic> m, Uint8List w) =>
      LocalPolicy.fromBundle(
        m,
        w,
        expectedObservationSchema: 'test-vector-v1',
        expectedRulesSchemaVersion: 'test-rules-v1',
        expectedActions: ['coast', 'left'],
        expectedInputSize: 2,
      );

  test(
    'LE float32 row-major W[out,in] followed by bias; deterministic tie',
    () {
      final bytes = encode(values);
      final policy = load(manifest(bytes), bytes);
      final result = policy.evaluate([2, 1]);
      expect(result.logits, [4.5, 0]);
      expect(result.actionId, 'coast');
      expect(() => result.logits[0] = 9, throwsUnsupportedError);
      final ties = encode(List.filled(6, 0.0));
      expect(load(manifest(ties), ties).evaluate([1, 2]).actionIndex, 0);
    },
  );
  test(
    'reject corrupt digest, mismatched schemas, shapes, and oversized data',
    () {
      final bytes = encode(values);
      for (final change in <Map<String, dynamic>>[
        {'weightsSha256': 'bad'},
        {'observationSchema': 'other'},
        {'rulesSchemaVersion': 'other'},
        {
          'actions': ['left', 'coast'],
        },
        {
          'layers': [
            {'inputs': 3, 'outputs': 2, 'activation': 'linear'},
          ],
        },
        {
          'layers': [
            {'inputs': 2, 'outputs': 2, 'activation': 'softmax'},
          ],
        },
      ]) {
        expect(
          () => load({...manifest(bytes), ...change}, bytes),
          throwsFormatException,
        );
      }
      final huge = Uint8List(400004);
      expect(() => load(manifest(huge), huge), throwsFormatException);
      final bad = encode([...values.take(5), double.nan]);
      expect(() => load(manifest(bad), bad), throwsFormatException);
      final policy = load(manifest(bytes), bytes);
      expect(() => policy.evaluate([1]), throwsArgumentError);
      expect(() => policy.evaluate([double.infinity, 0]), throwsArgumentError);
    },
  );
  test('hidden ReLU, tanh, shape composition', () {
    final bytes = encode([1, -1, 0, 0, 1, 1, 0]);
    final m = manifest(bytes)
      ..['actions'] = ['coast']
      ..['layers'] = [
        {'inputs': 1, 'outputs': 2, 'activation': 'relu'},
        {'inputs': 2, 'outputs': 1, 'activation': 'linear'},
      ];
    final policy = LocalPolicy.fromBundle(
      m,
      bytes,
      expectedObservationSchema: 'test-vector-v1',
      expectedRulesSchemaVersion: 'test-rules-v1',
      expectedActions: ['coast'],
    );
    expect(policy.evaluate([-2]).logits, [2]);
    m['layers'][0]['activation'] = 'tanh';
    final tanhPolicy = LocalPolicy.fromBundle(
      m,
      bytes,
      expectedObservationSchema: 'test-vector-v1',
      expectedRulesSchemaVersion: 'test-rules-v1',
      expectedActions: ['coast'],
    );
    expect(tanhPolicy.evaluate([1000]).logits, [0]);
  });
  test(
    'asset loader validates, warms up and reports missing/corrupt bundles',
    () async {
      final bytes = encode(values);
      final bundle = _FixtureBundle({
        'assets/policies/test/manifest.json': Uint8List.fromList(
          utf8.encode(jsonEncode(manifest(bytes))),
        ),
        'assets/policies/test/weights.bin': bytes,
      });
      Future<PolicyLoadResult> loadAssets() => PolicyLoader.load(
        assetDirectory: 'assets/policies/test',
        bundle: bundle,
        expectedObservationSchema: 'test-vector-v1',
        expectedRulesSchemaVersion: 'test-rules-v1',
        expectedActions: ['coast', 'left'],
        expectedInputSize: 2,
      );
      expect((await loadAssets()).isReady, true);
      bundle.files['assets/policies/test/weights.bin'] = encode(
        List.filled(6, 0.0),
      );
      expect((await loadAssets()).error, contains('checksum'));
      bundle.files.clear();
      expect((await loadAssets()).isReady, false);
    },
  );
  test('loader returns fallback readiness rather than throwing', () async {
    final result = await PolicyLoader.load(
      assetDirectory: '../invalid',
      expectedObservationSchema: 'test',
      expectedRulesSchemaVersion: 'test',
      expectedActions: ['coast'],
    );
    expect(result.isReady, false);
    expect(result.error, contains('Invalid policy asset directory'));
  });
}

class _FixtureBundle extends CachingAssetBundle {
  _FixtureBundle(this.files);
  final Map<String, Uint8List> files;
  @override
  Future<ByteData> load(String key) async {
    final bytes = files[key];
    if (bytes == null) throw StateError('Missing fixture asset');
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode((await load(key)).buffer.asUint8List());
}
