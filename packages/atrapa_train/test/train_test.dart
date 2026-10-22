import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:atrapa_train/atrapa_train.dart';
import 'package:test/test.dart';

// The app's own evaluator (pure Dart; imports only package:crypto).
import '../../../lib/policy/local_policy.dart';

void main() {
  test('backward pass matches finite differences', () {
    final sizes = [6, 5, 4, 3];
    final m = Mlp.init(sizes, math.Random(3));
    final tr = Trainer(sizes, Float32List.fromList(m.params));
    final x = Float32List.fromList([0.3, -0.2, 0.9, 0.1, -0.7, 0.5]);
    tr.accumulate(x, 2, 1.0);
    double loss(Float32List p) {
      final y = Mlp(sizes, p).forward(x);
      final mx = y.reduce(math.max);
      final s = y.fold(0.0, (a, v) => a + math.exp(v - mx));
      return -(y[2] - mx - math.log(s));
    }
    for (final i in [0, 7, 29, 30, 40, 55, tr.params.length - 1]) {
      final p = Float32List.fromList(m.params);
      const h = 1e-3;
      p[i] += h;
      final up = loss(p);
      p[i] -= 2 * h;
      final dn = loss(p);
      expect(tr.grad[i], closeTo((up - dn) / (2 * h), 2e-3), reason: 'param $i');
    }
  });

  test('relative action mapping round-trips', () {
    for (final h in Heading.values) {
      for (var a = 0; a < 3; a++) {
        expect(actionFor(h, headingFor(h, a)), a);
      }
    }
  });

  test('imitation learns the teacher on a tiny dataset (smoke)', () async {
    final d = await teacherDataset(200, 4, 0.1, 1);
    final tr = Trainer(archSizes, Mlp.init(archSizes, math.Random(1)).params);
    expect(imitate(tr, d, epochs: 4, batch: 64), greaterThan(0.6));
  });

  test('exported bundles load in the app evaluator and match parity (1e-5)', () {
    final root = Directory('../../assets/policies');
    final dirs = root.existsSync()
        ? root.listSync().whereType<Directory>().where(
            (d) => File('${d.path}/manifest.json').existsSync())
        : const <Directory>[];
    for (final dir in dirs) {
      final manifest = jsonDecode(
          File('${dir.path}/manifest.json').readAsStringSync());
      final policy = LocalPolicy.fromBundle(
        manifest as Map<String, dynamic>,
        File('${dir.path}/weights.bin').readAsBytesSync(),
        expectedObservationSchema: observationSchema,
        expectedActions: policyActions,
        expectedRulesSchemaVersion: rulesSchemaVersion,
        expectedInputSize: observationSize,
      );
      final parity = jsonDecode(
          File('${dir.path}/parity.json').readAsStringSync()) as List;
      final fresh = referenceObservations();
      expect(parity.length, fresh.length);
      for (var k = 0; k < parity.length; k++) {
        final stored = [
          for (final v in parity[k]['observation'] as List) (v as num).toDouble()
        ];
        expect(Float32List.fromList(stored), fresh[k],
            reason: 'encoder drift, ${dir.path} item $k');
        final d = policy.evaluate(stored);
        final want = (parity[k]['logits'] as List).cast<num>();
        for (var i = 0; i < want.length; i++) {
          expect(d.logits[i], closeTo(want[i].toDouble(), 1e-5));
        }
        expect(d.actionId, parity[k]['action']);
      }
    }
  });
}
