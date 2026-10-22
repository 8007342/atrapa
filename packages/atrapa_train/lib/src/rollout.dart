import 'dart:math' as math;
import 'dart:typed_data';

import 'package:atrapa_rules/atrapa_rules.dart';

import 'mlp.dart';

/// Relative action index (policyActions order: coast, left, right) to heading.
Heading headingFor(Heading cur, int action) => switch (action) {
      1 => Heading.values[(cur.index + 3) % 4],
      2 => Heading.values[(cur.index + 1) % 4],
      _ => cur,
    };

/// Heading chosen relative to the current one (0 coast, 1 left, 2 right).
int actionFor(Heading cur, Heading chosen) => chosen == cur
    ? 0
    : (chosen == Heading.values[(cur.index + 3) % 4] ? 1 : 2);

Float32List observe(RulesMatch m, int id) =>
    Float32List.fromList(encodeObservation(m, id));

/// Small seeded PRNG (trainer-only randomness; never used by the engine).
class Lcg {
  int s;
  Lcg(int seed) : s = (seed * 2654435761 + 1) & 0x7fffffff;
  int next() => s = (s * 1103515245 + 12345) & 0x7fffffff;
  int nextInt(int n) => next() % n;
  double nextDouble() => next() / 0x80000000;
}

abstract class Controller {
  Heading decide(RulesMatch m, int id);
}

/// The engine's own FreeSpaceBot (the teacher).
class TeacherController implements Controller {
  @override
  Heading decide(RulesMatch m, int id) =>
      const FreeSpaceBot().chooseDirection(m, id);
}

class RandomController implements Controller {
  final Lcg rng;
  RandomController(int seed) : rng = Lcg(seed);
  @override
  Heading decide(RulesMatch m, int id) =>
      headingFor(m.snakes[id].heading, rng.nextInt(3));
}

/// Policy seat. Greedy unless [sampleRng] is given (softmax sampling).
class PolicyController implements Controller {
  final Mlp mlp;
  final Lcg? sampleRng;
  final bool record;
  final List<Float32List> obs = [];
  final List<int> actions = [];
  PolicyController(this.mlp, {this.sampleRng, this.record = false});

  @override
  Heading decide(RulesMatch m, int id) {
    final x = observe(m, id);
    final y = mlp.forward(x);
    var a = 0;
    if (sampleRng == null) {
      for (var i = 1; i < y.length; i++) {
        if (y[i] > y[a]) a = i;
      }
    } else {
      var mx = y[0];
      for (final v in y) {
        if (v > mx) mx = v;
      }
      final p = [for (final v in y) math.exp(v - mx)];
      var r = sampleRng!.nextDouble() * p.fold(0.0, (s, v) => s + v);
      a = p.length - 1;
      for (var i = 0; i < p.length; i++) {
        r -= p[i];
        if (r <= 0) {
          a = i;
          break;
        }
      }
    }
    if (record) {
      obs.add(x);
      actions.add(a);
    }
    return headingFor(m.snakes[id].heading, a);
  }
}

MatchConfig configFor(int snakes, int seed) =>
    MatchConfig(snakeCount: snakes, seed: seed);

/// Play one match. Decisions are taken for every living snake at a cell
/// boundary (substep 0) from the same pre-step state, queued together, and
/// then the engine advances one substep — the app's beforeCellStep contract.
RulesMatch playEpisode(List<Controller> seats, int seed) {
  final m = RulesMatch(configFor(seats.length, seed));
  while (!m.isOver) {
    final ready = [
      for (final s in m.snakes)
        if (s.alive && s.substep == 0) s.id
    ];
    final choices = {for (final id in ready) id: seats[id].decide(m, id)};
    choices.forEach(m.queueDirection);
    m.stepSubstep();
  }
  return m;
}

/// Teacher episode for imitation: every seat follows the teacher except
/// that with probability [eps] it plays a random relative move (state
/// diversity). Every boundary decision is labelled with the teacher's move.
void teacherEpisode(int numSnakes, int seed, double eps,
    List<Float32List> obsOut, List<int> labelOut) {
  final m = RulesMatch(configFor(numSnakes, seed));
  final rng = Lcg(seed ^ 0x5bd1e995);
  const teacher = FreeSpaceBot();
  while (!m.isOver) {
    final choices = <int, Heading>{};
    for (final s in m.snakes) {
      if (!s.alive || s.substep != 0) continue;
      final label = actionFor(s.heading, teacher.chooseDirection(m, s.id));
      obsOut.add(observe(m, s.id));
      labelOut.add(label);
      final a = rng.nextDouble() < eps ? rng.nextInt(3) : label;
      choices[s.id] = headingFor(s.heading, a);
    }
    choices.forEach(m.queueDirection);
    m.stepSubstep();
  }
}
