import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:atrapa_train/atrapa_train.dart';

/// dart run bin/atrapa_train.dart [--smoke] [--name ID] [--out DIR]
///   [--episodes N] [--epochs N] [--selfplay-minutes M] [--workers N]
///   [--eval-games N]
Future<void> main(List<String> args) async {
  String opt(String k, String d) {
    final i = args.indexOf('--$k');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : d;
  }

  final smoke = args.contains('--smoke');
  final name = opt('name', smoke ? 'smoke' : 'freespace-v1');
  final out = opt('out', '../../target/policies/$name');
  final workers = int.parse(opt('workers', '${Platform.numberOfProcessors}'));
  final episodes = int.parse(opt('episodes', smoke ? '12' : '6000'));
  final epochs = int.parse(opt('epochs', smoke ? '1' : '8'));
  final spMinutes = double.parse(opt('selfplay-minutes', smoke ? '0.05' : '40'));
  final evalGames = int.parse(opt('eval-games', smoke ? '6' : '400'));
  final sw = Stopwatch()..start();

  log('rules=$rulesSchemaVersion obs=$observationSchema/$observationSize '
      'actions=$policyActions episodes=$episodes workers=$workers');
  final data = await teacherDataset(episodes, workers, 0.1, 1);
  log('dataset samples=${data.n} (${sw.elapsed.inSeconds}s)');

  final tr = Trainer(archSizes, Mlp.init(archSizes, math.Random(7)).params);
  final tImit = Stopwatch()..start();
  final acc = imitate(tr, data, epochs: epochs);
  tImit.stop();
  log('imitation done heldout_acc=${acc.toStringAsFixed(4)} '
      'wall=${tImit.elapsed.inSeconds}s params=${tr.params.length}');
  final imitation = Float32List.fromList(tr.params);

  // A self-play checkpoint replaces the imitation weights only if it scores
  // better vs the teacher on selection seeds disjoint from the eval seeds.
  Future<double> select(Float32List p) async {
    var sc = 0.0;
    for (var k = 1; k <= 3; k++) {
      final r = await evaluate(p, 'teacher', k, smoke ? 6 : 120, workers,
          seedBase: selectSeedBase);
      sc += (r.w - r.l) / r.n;
    }
    return sc;
  }

  var best = Float32List.fromList(imitation);
  var bestScore = await select(best);
  final imitationScore = bestScore;
  log('selection score imitation=${bestScore.toStringAsFixed(3)}');
  final pool = <Float32List>[Float32List.fromList(imitation)];
  final tSp = Stopwatch()..start();
  var iter = 0, adopted = 0;
  var baseline = 0.0;
  while (tSp.elapsedMilliseconds < spMinutes * 60000) {
    iter++;
    final (obs, acts, rets, score) = await selfPlayBatch(
        tr.params, pool, smoke ? 8 : 256, workers, 2000000 + iter * 1000);
    final meanRet =
        rets.isEmpty ? 0.0 : rets.reduce((a, b) => a + b) / rets.length;
    baseline = iter == 1 ? meanRet : 0.9 * baseline + 0.1 * meanRet;
    final order = List<int>.generate(obs.length, (i) => i)
      ..shuffle(math.Random(iter));
    const batch = 1024;
    for (var b = 0; b < order.length; b += batch) {
      final end = math.min(b + batch, order.length);
      for (var k = b; k < end; k++) {
        final i = order[k];
        tr.accumulate(obs[i], acts[i], rets[i] - baseline, entropyBeta: 0.01);
      }
      tr.adam(end - b, 1e-4, wd: 0);
    }
    if (iter % 5 == 0) {
      pool.add(Float32List.fromList(tr.params));
      if (pool.length > 8) pool.removeAt(1);
      final sc = await select(tr.params);
      final keep = sc > bestScore;
      if (keep) {
        bestScore = sc;
        best = Float32List.fromList(tr.params);
        adopted = iter;
      }
      log('selfplay iter=$iter samples=${obs.length} outcome=${score.toStringAsFixed(3)} '
          'select=${sc.toStringAsFixed(3)} best=${bestScore.toStringAsFixed(3)}${keep ? ' *' : ''}');
    }
  }
  tSp.stop();
  final trainWall = sw.elapsed;

  log('final evaluation games=$evalGames per cell');
  final table = <String, Object>{};
  for (final opp in ['teacher', 'random']) {
    for (var k = 1; k <= 3; k++) {
      final r = await evaluate(best, opp, k, evalGames, workers);
      table['1v$k-$opp'] = r.toJson();
      log('policy 1v$k-$opp $r');
    }
  }
  for (var k = 1; k <= 3; k++) {
    final r = await evaluate(null, 'teacher', k, evalGames, workers);
    table['baseline-teacher-1v$k-teacher'] = r.toJson();
    log('teacher-baseline 1v$k-teacher $r');
  }

  final modelId = '$name-${DateTime.now().toUtc().toIso8601String().substring(0, 10)}'
      '-it$adopted';
  exportBundle(out, modelId, best, {
    'trainer': 'packages/atrapa_train (pure Dart, CPU)',
    'host': Platform.localHostname,
    'device': 'cpu, $workers isolates',
    'dart': Platform.version.split(' ').first,
    'teacher': 'atrapa_rules FreeSpaceBot()',
    'imitation': {
      'episodes': episodes,
      'teacherEpsilon': 0.1,
      'samples': data.n,
      'epochs': epochs,
      'heldoutAccuracy': acc,
      'wallSeconds': tImit.elapsed.inMilliseconds / 1000,
      'initSeed': 7,
    },
    'selfplay': {
      'iterations': iter,
      'adoptedIteration': adopted,
      'wallSeconds': tSp.elapsed.inMilliseconds / 1000,
      'selectionScoreImitation': imitationScore,
      'selectionScoreAdopted': bestScore,
      'selectionSeeds': '$selectSeedBase+',
    },
    'trainingWallSeconds': trainWall.inMilliseconds / 1000,
    'evaluation': {
      'seeds': '$evalSeedBase + game, policy seat = game % snakes, games=$evalGames per cell',
      'results': table,
    },
  });
  log('exported $out model=$modelId total_wall=${sw.elapsed.inSeconds}s '
      'training_wall=${trainWall.inSeconds}s adopted_iter=$adopted');
}
