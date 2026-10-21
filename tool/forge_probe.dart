// Infrastructure experiment only: this synthetic XOR network is not a game AI.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const payloadBytes = 8 * 1024 * 1024;
const probeSchema = 'atrapa-forge-probe-v1';

void atomicJson(Directory dir, String name, Map<String, Object?> value) {
  final temp = File('${dir.path}/$name.$pid.tmp');
  temp.writeAsStringSync('${jsonEncode(value)}\n', flush: true);
  temp.renameSync('${dir.path}/$name');
}

Map<String, dynamic> readJson(Directory dir, String name) =>
    jsonDecode(File('${dir.path}/$name').readAsStringSync())
        as Map<String, dynamic>;

Map<String, Object?> writePayload(Directory dir) {
  dir.createSync(recursive: true);
  final watch = Stopwatch()..start();
  final data = Uint8List(payloadBytes);
  for (var i = 0; i < data.length; i++) {
    data[i] = i % 251;
  }
  final temp = File('${dir.path}/payload.bin.$pid.tmp');
  temp.writeAsBytesSync(data, flush: true);
  temp.renameSync('${dir.path}/payload.bin');
  final result = <String, Object?>{
    'schema': probeSchema,
    'bytes': data.length,
    'pattern': 'byte[index] = index % 251',
    'writeFlushRenameMs': watch.elapsedMicroseconds / 1000,
    'pid': pid,
    'utc': DateTime.now().toUtc().toIso8601String(),
  };
  atomicJson(dir, 'payload-manifest.json', result);
  return result;
}

Map<String, Object?> verifyPayload(Directory dir) {
  final watch = Stopwatch()..start();
  final manifest = readJson(dir, 'payload-manifest.json');
  if (manifest['schema'] != probeSchema || manifest['bytes'] != payloadBytes) {
    throw StateError('Invalid probe manifest');
  }
  final data = File('${dir.path}/payload.bin').readAsBytesSync();
  if (data.length != payloadBytes) throw StateError('Payload length mismatch');
  for (var i = 0; i < data.length; i++) {
    if (data[i] != i % 251) throw StateError('Payload mismatch at byte $i');
  }
  return {
    'schema': probeSchema,
    'verifiedBytes': data.length,
    'readAndVerifyMs': watch.elapsedMicroseconds / 1000,
    'readerPid': pid,
    'writerPid': manifest['pid'],
  };
}

/// Plain CPU gradient descent, deliberately without a framework dependency.
class ToyNetwork {
  final List<double> weights;
  int epochs;
  ToyNetwork(this.weights, this.epochs);

  factory ToyNetwork.initial() {
    final random = math.Random(1724);
    return ToyNetwork(List.generate(33, (_) => random.nextDouble() * 2 - 1), 0);
  }

  factory ToyNetwork.fromJson(Map<String, dynamic> value) {
    if (value['schema'] != probeSchema || value['architecture'] != '2-8-1') {
      throw StateError('Incompatible toy checkpoint');
    }
    final weights = (value['weights'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    if (weights.length != 33 || weights.any((e) => !e.isFinite)) {
      throw StateError('Invalid toy weights');
    }
    return ToyNetwork(weights, value['epochs'] as int);
  }

  double forward(double a, double b, List<double> hidden) {
    for (var h = 0; h < 8; h++) {
      final z =
          weights[h * 3] * a + weights[h * 3 + 1] * b + weights[h * 3 + 2];
      // tanh using a numerically bounded expression for this small fixture.
      hidden[h] = 2 / (1 + math.exp(-2 * z)) - 1;
    }
    var z = weights[32];
    for (var h = 0; h < 8; h++) {
      z += weights[24 + h] * hidden[h];
    }
    return 1 / (1 + math.exp(-z));
  }

  void train(int count) {
    final hidden = List.filled(8, 0.0);
    for (var epoch = 0; epoch < count; epoch++) {
      for (var row = 0; row < 4; row++) {
        final a = (row ~/ 2).toDouble();
        final b = (row % 2).toDouble();
        final target = ((row ~/ 2) ^ (row % 2)).toDouble();
        final delta = forward(a, b, hidden) - target;
        for (var h = 0; h < 8; h++) {
          final back = delta * weights[24 + h] * (1 - hidden[h] * hidden[h]);
          weights[h * 3] -= .1 * back * a;
          weights[h * 3 + 1] -= .1 * back * b;
          weights[h * 3 + 2] -= .1 * back;
          weights[24 + h] -= .1 * delta * hidden[h];
        }
        weights[32] -= .1 * delta;
      }
      epochs++;
    }
  }

  List<double> predictions() => List.generate(
    4,
    (row) => forward(
      (row ~/ 2).toDouble(),
      (row % 2).toDouble(),
      List.filled(8, 0.0),
    ),
  );

  double loss() {
    final outputs = predictions();
    var total = 0.0;
    for (var row = 0; row < 4; row++) {
      final target = ((row ~/ 2) ^ (row % 2)).toDouble();
      final p = outputs[row].clamp(1e-12, 1 - 1e-12);
      total -= target * math.log(p) + (1 - target) * math.log(1 - p);
    }
    return total / 4;
  }

  Map<String, Object?> toJson() => {
    'schema': probeSchema,
    'purpose': 'synthetic XOR infrastructure smoke test, not gameplay',
    'architecture': '2-8-1',
    'epochs': epochs,
    'weights': weights,
  };
}

void main(List<String> args) {
  if (args.length != 2 ||
      !['write', 'read', 'train', 'resume'].contains(args[0])) {
    stderr.writeln(
      'Usage: dart tool/forge_probe.dart write|read|train|resume ABSOLUTE_DIR',
    );
    exitCode = 64;
    return;
  }
  final dir = Directory(args[1]);
  if (!dir.isAbsolute) throw ArgumentError('Probe directory must be absolute');
  dir.createSync(recursive: true);
  final watch = Stopwatch()..start();
  late Map<String, Object?> result;
  switch (args[0]) {
    case 'write':
      result = writePayload(dir);
    case 'read':
      result = verifyPayload(dir);
    case 'train':
      final network = ToyNetwork.initial();
      final initialLoss = network.loss();
      network.train(6000);
      if (network.loss() >= .01) {
        throw StateError('Toy training did not converge');
      }
      atomicJson(dir, 'toy-checkpoint.json', network.toJson());
      result = {
        'initialLoss': initialLoss,
        'finalLoss': network.loss(),
        'epochs': network.epochs,
        'predictions': network.predictions(),
      };
    case 'resume':
      final network = ToyNetwork.fromJson(readJson(dir, 'toy-checkpoint.json'));
      network.train(6000);
      final reference = ToyNetwork.initial()..train(12000);
      if (network.epochs != reference.epochs ||
          List.generate(
            33,
            (i) => network.weights[i] == reference.weights[i],
          ).any((equal) => !equal)) {
        throw StateError('Resumed weights differ from uninterrupted training');
      }
      atomicJson(dir, 'toy-resumed.json', network.toJson());
      result = {
        'epochs': network.epochs,
        'loss': network.loss(),
        'exactResumeParity': true,
        'predictions': network.predictions(),
      };
  }
  result.addAll({
    'mode': args[0],
    'elapsedMs': watch.elapsedMicroseconds / 1000,
    'currentRssBytes': ProcessInfo.currentRss,
    'dart': Platform.version.split(' ').first,
  });
  atomicJson(dir, '${args[0]}-result.json', result);
  stdout.writeln(jsonEncode(result));
}
