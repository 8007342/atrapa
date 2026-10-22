import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Immutable, feed-forward policy. No game state or timing authority lives here.
class LocalPolicy {
  LocalPolicy._(
    this.modelId,
    this.observationSchema,
    this.actions,
    this._layers,
  );

  final String modelId;
  final String observationSchema;
  final List<String> actions;
  final List<_Layer> _layers;
  int get inputSize => _layers.first.inputs;

  static LocalPolicy fromBundle(
    Map<String, dynamic> manifest,
    Uint8List weights, {
    required String expectedObservationSchema,
    required List<String> expectedActions,
    required String expectedRulesSchemaVersion,
    int? expectedInputSize,
  }) {
    Never reject(String message) => throw FormatException(message);
    if (manifest['format'] != 'atrapa-dense-v1' ||
        manifest['numericFormat'] != 'float32-le' ||
        manifest['normalization'] != 'encoder-owned' ||
        manifest['output'] != 'logits-argmax-first') {
      reject('Unsupported policy format or interpretation');
    }
    if (manifest['rulesSchemaVersion'] != expectedRulesSchemaVersion ||
        expectedRulesSchemaVersion.isEmpty) {
      reject('Rules schema mismatch');
    }
    if (manifest['observationSchema'] != expectedObservationSchema ||
        expectedObservationSchema.isEmpty) {
      reject('Observation schema mismatch');
    }
    final actionData = manifest['actions'];
    if (actionData is! List ||
        actionData.isEmpty ||
        actionData.length != expectedActions.length ||
        expectedActions.toSet().length != expectedActions.length) {
      reject('Action schema mismatch');
    }
    for (var i = 0; i < actionData.length; i++) {
      if (actionData[i] != expectedActions[i]) reject('Action schema mismatch');
    }
    final id = manifest['modelId'];
    if (id is! String || id.isEmpty) reject('Missing model identity');
    if (weights.length > 400000 ||
        weights.length % 4 != 0 ||
        sha256.convert(weights).toString() != manifest['weightsSha256']) {
      reject('Invalid weight size or checksum');
    }
    final definitions = manifest['layers'];
    if (definitions is! List ||
        definitions.isEmpty ||
        definitions.length > 16) {
      reject('Invalid layer list');
    }
    final data = ByteData.sublistView(weights);
    var offset = 0;
    double read() {
      if (offset + 4 > weights.length) reject('Truncated weights');
      final value = data.getFloat32(offset, Endian.little);
      offset += 4;
      if (!value.isFinite) reject('Nonfinite weight');
      return value;
    }

    final layers = <_Layer>[];
    for (final definition in definitions) {
      if (definition is! Map) reject('Invalid layer');
      final inputs = definition['inputs'];
      final outputs = definition['outputs'];
      final activation = definition['activation'];
      if (inputs is! int ||
          outputs is! int ||
          inputs <= 0 ||
          outputs <= 0 ||
          inputs > 100000 ||
          outputs > 100000 ||
          (inputs + 1) * outputs > 100000 ||
          !['linear', 'relu', 'tanh'].contains(activation)) {
        reject('Invalid layer dimensions or activation');
      }
      if (layers.isNotEmpty && layers.last.outputs != inputs) {
        reject('Disconnected layer shapes');
      }
      layers.add(
        _Layer(
          inputs,
          outputs,
          activation as String,
          List.generate(inputs * outputs, (_) => read(), growable: false),
          List.generate(outputs, (_) => read(), growable: false),
        ),
      );
    }
    if ((expectedInputSize != null &&
            layers.first.inputs != expectedInputSize) ||
        offset != weights.length ||
        layers.last.outputs != actionData.length ||
        layers.last.activation != 'linear') {
      reject('Weight count or output shape mismatch');
    }
    return LocalPolicy._(
      id,
      expectedObservationSchema,
      List.unmodifiable(expectedActions),
      List.unmodifiable(layers),
    );
  }

  PolicyDecision evaluate(List<double> observation) {
    if (observation.length != inputSize ||
        observation.any((v) => !v.isFinite)) {
      throw ArgumentError('Invalid policy observation');
    }
    var values = observation;
    for (final layer in _layers) {
      values = List.generate(layer.outputs, (row) {
        var sum = layer.biases[row];
        for (var col = 0; col < layer.inputs; col++) {
          sum += layer.weights[row * layer.inputs + col] * values[col];
        }
        if (!sum.isFinite) throw StateError('Nonfinite policy intermediate');
        return switch (layer.activation) {
          'relu' => math.max(0.0, sum),
          'tanh' =>
            sum >= 0
                ? (1 - math.exp(-2 * sum)) / (1 + math.exp(-2 * sum))
                : (math.exp(2 * sum) - 1) / (math.exp(2 * sum) + 1),
          _ => sum,
        };
      }, growable: false);
    }
    var winner = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[winner]) winner = i;
    }
    return PolicyDecision(winner, actions[winner], List.unmodifiable(values));
  }
}

class PolicyDecision {
  const PolicyDecision(this.actionIndex, this.actionId, this.logits);
  final int actionIndex;
  final String actionId;
  final List<double> logits;
}

class _Layer {
  const _Layer(
    this.inputs,
    this.outputs,
    this.activation,
    this.weights,
    this.biases,
  );
  final int inputs;
  final int outputs;
  final String activation;
  final List<double> weights;
  final List<double> biases;
}
