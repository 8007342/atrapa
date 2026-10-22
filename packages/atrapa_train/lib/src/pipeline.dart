import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:crypto/crypto.dart';

import 'mlp.dart';
import 'nn.dart';
import 'rollout.dart';

const archSizes = [observationSize, 64, 32, 3];
const evalSeedBase = 1000000;
const selectSeedBase = 500000;

void log(String m) =>
    stdout.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] $m');

class Dataset {
  final Float32List obs;
  final Uint8List labels;
  Dataset(this.obs, this.labels);
  int get n => labels.length;
}

Future<Dataset> teacherDataset(
    int episodes, int workers, double eps, int seedBase) async {
  final parts = await Future.wait([
    for (var w = 0; w < workers; w++)
      Isolate.run(() {
        final o = <Float32List>[];
        final l = <int>[];
        for (var e = w; e < episodes; e += workers) {
          teacherEpisode(2 + (e % 3), seedBase + e, eps, o, l);
        }
        final flat = Float32List(o.length * observationSize);
        for (var i = 0; i < o.length; i++) {
          flat.setAll(i * observationSize, o[i]);
        }
        return (flat, Uint8List.fromList(l));
      })
  ]);
  final n = parts.fold(0, (a, p) => a + p.$2.length);
  final obs = Float32List(n * observationSize);
  final labels = Uint8List(n);
  var k = 0;
  for (final (o, l) in parts) {
    obs.setAll(k * observationSize, o);
    labels.setAll(k, l);
    k += l.length;
  }
  return Dataset(obs, labels);
}

Float32List _row(Dataset d, int i) => Float32List.sublistView(
    d.obs, i * observationSize, (i + 1) * observationSize);

/// Supervised imitation with AdamW and cosine LR. Returns held-out accuracy.
double imitate(Trainer tr, Dataset d,
    {int epochs = 4, int batch = 256, double lr = 2e-3, int seed = 1}) {
  final rand = math.Random(seed);
  final idx = List<int>.generate(d.n, (i) => i)..shuffle(rand);
  final hold = (d.n * 0.05).floor();
  final test = idx.sublist(0, hold), train = idx.sublist(hold);
  final steps = math.max(1, epochs * (train.length ~/ batch));
  var step = 0;
  for (var ep = 0; ep < epochs; ep++) {
    train.shuffle(rand);
    var loss = 0.0, correct = 0, seen = 0;
    for (var b = 0; b + batch <= train.length; b += batch) {
      for (var k = b; k < b + batch; k++) {
        final (l, ok) = tr.accumulate(_row(d, train[k]), d.labels[train[k]], 1.0);
        loss += l;
        if (ok) correct++;
        seen++;
      }
      tr.adam(batch, lr * 0.5 * (1 + math.cos(math.pi * step / steps)));
      step++;
    }
    log('imitation epoch ${ep + 1}/$epochs loss=${(loss / math.max(1, seen)).toStringAsFixed(4)} '
        'train_acc=${(correct / math.max(1, seen)).toStringAsFixed(4)} '
        'heldout_acc=${heldoutAcc(tr, d, test).toStringAsFixed(4)}');
  }
  return heldoutAcc(tr, d, test);
}

double heldoutAcc(Trainer tr, Dataset d, List<int> test) {
  final m = Mlp(tr.sizes, tr.params);
  var ok = 0;
  for (final i in test) {
    if (m.argmax(_row(d, i)) == d.labels[i]) ok++;
  }
  return test.isEmpty ? 0 : ok / test.length;
}

class Wdl {
  int w = 0, d = 0, l = 0;
  int get n => w + d + l;
  double get winRate => n == 0 ? 0 : w / n;
  @override
  String toString() => 'W$w/D$d/L$l (${(100 * winRate).toStringAsFixed(1)}%)';
  Map<String, Object> toJson() =>
      {'win': w, 'draw': d, 'loss': l, 'games': n, 'win_rate': winRate};
}

/// Policy (null = the teacher itself, as a baseline) in seat `game % n` vs
/// [opponents] opponents of [oppKind] ('teacher' | 'random'), fixed seeds.
/// Win = sole survivor; draw = tick limit or everyone eliminated together.
Future<Wdl> evaluate(Float32List? policy, String oppKind, int opponents,
    int games, int workers, {int seedBase = evalSeedBase}) async {
  final res = await Future.wait([
    for (var w = 0; w < workers; w++)
      Isolate.run(() {
        final r = [0, 0, 0];
        for (var g = w; g < games; g += workers) {
          final seed = seedBase + g;
          final n = opponents + 1;
          final seat = g % n;
          final seats = <Controller>[
            for (var i = 0; i < n; i++)
              i == seat
                  ? (policy == null
                      ? TeacherController()
                      : PolicyController(Mlp(archSizes, policy)))
                  : (oppKind == 'teacher'
                      ? TeacherController()
                      : RandomController(seed * 7 + i))
          ];
          final m = playEpisode(seats, seed);
          if (m.winnerId == seat) {
            r[0]++;
          } else if (m.snakes[seat].alive || m.endReason == 'all-eliminated') {
            r[1]++;
          } else {
            r[2]++;
          }
        }
        return r;
      })
  ]);
  final out = Wdl();
  for (final r in res) {
    out.w += r[0];
    out.d += r[1];
    out.l += r[2];
  }
  return out;
}

/// Self-play batch: learner (sampled) in a random seat vs a 50/50 mix of the
/// teacher and frozen snapshots. Returns (obs, action, return, mean outcome).
Future<(List<Float32List>, List<int>, List<double>, double)> selfPlayBatch(
    Float32List learner,
    List<Float32List> pool,
    int episodes,
    int workers,
    int seedBase) async {
  final res = await Future.wait([
    for (var w = 0; w < workers; w++)
      Isolate.run(() {
        final obs = <Float32List>[];
        final acts = <int>[];
        final rets = <double>[];
        var score = 0.0;
        for (var e = w; e < episodes; e += workers) {
          final seed = seedBase + e;
          final r = Lcg(seed * 31 + 7);
          final n = 2 + r.nextInt(3);
          final seat = r.nextInt(n);
          final me = PolicyController(Mlp(archSizes, learner),
              sampleRng: Lcg(seed), record: true);
          final seats = <Controller>[
            for (var i = 0; i < n; i++)
              i == seat
                  ? me
                  : (r.nextDouble() < 0.5
                      ? TeacherController()
                      : PolicyController(
                          Mlp(archSizes, pool[r.nextInt(pool.length)]),
                          sampleRng: Lcg(seed + i)))
          ];
          final m = playEpisode(seats, seed);
          final out = m.winnerId == seat
              ? 1.0
              : (m.snakes[seat].alive ? 0.0 : -1.0);
          score += out;
          final len = me.actions.length;
          for (var t = 0; t < len; t++) {
            obs.add(me.obs[t]);
            acts.add(me.actions[t]);
            rets.add(out * math.pow(0.99, len - 1 - t).toDouble());
          }
        }
        return (obs, acts, rets, score);
      })
  ]);
  final o = <Float32List>[], a = <int>[], r = <double>[];
  var score = 0.0;
  for (final p in res) {
    o.addAll(p.$1);
    a.addAll(p.$2);
    r.addAll(p.$3);
    score += p.$4;
  }
  return (o, a, r, score / episodes);
}

/// Fixed parity corpus: observations from teacher matches at set ticks.
List<Float32List> referenceObservations() {
  final out = <Float32List>[];
  for (var k = 0; k < 8; k++) {
    final m = RulesMatch(configFor(2 + (k % 3), 4242 + k));
    final stopAt = 20 * (k + 1);
    while (!m.isOver && m.tick < stopAt) {
      final c = {
        for (final s in m.snakes)
          if (s.alive && s.substep == 0)
            s.id: const FreeSpaceBot().chooseDirection(m, s.id)
      };
      c.forEach(m.queueDirection);
      m.stepSubstep();
    }
    out.add(observe(m, m.snakes.firstWhere((s) => s.alive).id));
  }
  return out;
}

/// Export in the app's `atrapa-dense-v1` contract (docs/policy-bundle.md):
/// manifest.json + weights.bin, plus parity.json (observations, logits and
/// chosen actions computed in float32 by the trainer's evaluator).
void exportBundle(String dir, String modelId, Float32List params,
    Map<String, Object?> provenance) {
  Directory(dir).createSync(recursive: true);
  final mlp = Mlp(archSizes, params);
  final bytes = mlp.encode();
  File('$dir/weights.bin').writeAsBytesSync(bytes);
  final manifest = {
    'format': 'atrapa-dense-v1',
    'modelId': modelId,
    'numericFormat': 'float32-le',
    'normalization': 'encoder-owned',
    'output': 'logits-argmax-first',
    'rulesSchemaVersion': rulesSchemaVersion,
    'observationSchema': observationSchema,
    'actions': policyActions,
    'weightsSha256': sha256.convert(bytes).toString(),
    'layers': [
      for (var l = 0; l + 1 < archSizes.length; l++)
        {
          'inputs': archSizes[l],
          'outputs': archSizes[l + 1],
          'activation': l + 2 == archSizes.length ? 'linear' : 'relu',
        }
    ],
    'parameterCount': params.length,
    'parity': {'file': 'parity.json', 'absoluteTolerance': 1e-5},
    'provenance': provenance,
  };
  File('$dir/manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(manifest));
  final parity = [
    for (final o in referenceObservations())
      () {
        final y = Float32List.fromList(mlp.forward(o));
        var a = 0;
        for (var i = 1; i < y.length; i++) {
          if (y[i] > y[a]) a = i;
        }
        return {
          'observation': [for (final v in o) v],
          'logits': [for (final v in y) v],
          'action': policyActions[a],
        };
      }()
  ];
  File('$dir/parity.json').writeAsStringSync(jsonEncode(parity));
}
