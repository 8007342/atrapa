import 'dart:convert';

import 'package:flutter/services.dart';

import 'local_policy.dart';

class PolicyLoadResult {
  const PolicyLoadResult.ready(LocalPolicy value)
    : policy = value,
      error = null;
  const PolicyLoadResult.fallback(String reason)
    : policy = null,
      error = reason;
  final LocalPolicy? policy;
  final String? error;
  bool get isReady => policy != null;
}

/// Asset failures are an explicit readiness state; callers keep their baseline.
class PolicyLoader {
  static Future<PolicyLoadResult> load({
    required String assetDirectory,
    required String expectedObservationSchema,
    required List<String> expectedActions,
    required String expectedRulesSchemaVersion,
    int? expectedInputSize,
    AssetBundle? bundle,
  }) async {
    try {
      if (!RegExp(r'^assets/policies/[a-zA-Z0-9_-]+$')
          .hasMatch(assetDirectory)) {
        throw const FormatException('Invalid policy asset directory');
      }
      final assets = bundle ?? rootBundle;
      final decoded = jsonDecode(
        await assets.loadString('$assetDirectory/manifest.json'),
      );
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid policy manifest');
      }
      final bytes = await assets.load('$assetDirectory/weights.bin');
      final policy = LocalPolicy.fromBundle(
        decoded,
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        expectedObservationSchema: expectedObservationSchema,
        expectedActions: expectedActions,
        expectedRulesSchemaVersion: expectedRulesSchemaVersion,
        expectedInputSize: expectedInputSize,
      );
      policy.evaluate(List.filled(policy.inputSize, 0.0));
      return PolicyLoadResult.ready(policy);
    } catch (error) {
      return PolicyLoadResult.fallback('Policy unavailable: $error');
    }
  }
}
