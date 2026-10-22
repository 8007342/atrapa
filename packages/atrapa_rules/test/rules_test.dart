import 'dart:convert';
import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:test/test.dart';

SnakeState snake(int id, List<GridCell> body, Heading h) =>
    SnakeState(id: id, body: body, heading: h);
RulesMatch fixture(List<SnakeState> snakes,
        {int growth = 100, int steps = 1}) =>
    RulesMatch.fromState(
        MatchConfig(
            width: 12,
            height: 12,
            snakeCount: snakes.length,
            growthEveryCells: growth,
            substepsPerCell: steps),
        snakes);
void main() {
  test('seed and ordered commands survive JSON replay', () {
    final replay =
        MatchReplay(MatchConfig(seed: 173, snakeCount: 3, tickLimit: 80), [
      const ReplayCommand(0, 0, Heading.down),
      const ReplayCommand(0, 0, Heading.up),
      const ReplayCommand(8, 1, Heading.up),
    ]);
    final decoded = MatchReplay.fromJson(
        jsonDecode(jsonEncode(replay.toJson())) as Map<String, dynamic>);
    final a = replay.run();
    final b = decoded.run();
    expect(a.tick, b.tick);
    expect(a.winnerId, b.winnerId);
    expect(a.snakes.map((s) => s.body.toString()).toList(),
        b.snakes.map((s) => s.body.toString()).toList());
    expect(
        () =>
            MatchReplay.fromJson({...replay.toJson(), 'rulesSchema': 'future'}),
        throwsFormatException);
  });

  test('tail vacates even when its owner hits a wall', () {
    final m = fixture([
      snake(
          0,
          [const GridCell(0, 2), const GridCell(1, 2), const GridCell(2, 2)],
          Heading.left),
      snake(1, [const GridCell(2, 3), const GridCell(3, 3)], Heading.up),
    ]);
    m.stepSubstep();
    expect(m.snakes.first.alive, false);
    expect(m.snakes.last.alive, true);
    expect(m.snakes.last.head, const GridCell(2, 2));
    expect(m.snakes.first.body.toSet().intersection(m.snakes.last.body.toSet()),
        isEmpty);
  });
  test('growing eliminated tail remains occupied', () {
    final m = fixture([
      snake(
          0,
          [const GridCell(0, 2), const GridCell(1, 2), const GridCell(2, 2)],
          Heading.left),
      snake(1, [const GridCell(2, 3), const GridCell(3, 3)], Heading.up),
    ], growth: 1);
    m.stepSubstep();
    expect(m.snakes.last.alive, false);
    expect(m.snakes.last.lossReason, 'body');
  });

  test('four exact substeps advance one cell, hook runs before turn', () {
    final m = RulesMatch(MatchConfig());
    final start = m.snakes.first.head;
    var calls = 0;
    m.beforeCellStep = (_) {
      calls++;
    };
    for (var i = 0; i < 3; i++) m.stepSubstep();
    expect(m.snakes.first.head, start);
    expect(m.snakes.first.substep, 3);
    m.stepSubstep();
    expect(m.snakes.first.head, start.moved(Heading.right));
    expect(calls, 1);
  });
  test('latest perpendicular wins, same/opposite do not reverse', () {
    final m = RulesMatch(MatchConfig());
    m.queueDirection(0, Heading.up);
    m.queueDirection(0, Heading.down);
    m.queueDirection(0, Heading.left);
    m.stepSubstep();
    expect(m.snakes.first.heading, Heading.down);
  });
  test('turn pressed mid-cell is buffered until following cell', () {
    final m = RulesMatch(MatchConfig());
    m.stepSubstep();
    m.queueDirection(0, Heading.down);
    for (var i = 0; i < 3; i++) m.stepSubstep();
    expect(m.snakes.first.heading, Heading.right);
    m.stepSubstep();
    expect(m.snakes.first.heading, Heading.down);
  });
  test('wall loss gives last survivor', () {
    final m = fixture([
      snake(0, [const GridCell(0, 0)], Heading.left),
      snake(1, [const GridCell(8, 8)], Heading.left)
    ]);
    m.stepSubstep();
    expect(m.winnerId, 1);
    expect(m.snakes.first.lossReason, 'wall');
  });
  test('same target and swapping heads kill both', () {
    for (final swap in [false, true]) {
      final m = fixture([
        snake(0, [const GridCell(3, 3)], Heading.right),
        snake(1, [GridCell(swap ? 4 : 5, 3)], Heading.left)
      ]);
      m.stepSubstep();
      expect(m.isOver, true);
      expect(m.winnerId, isNull);
      expect(m.snakes.every((s) => s.lossReason == 'head-on'), true);
    }
  });
  test('self body loses, but non-growing tail may vacate', () {
    final body = [
      const GridCell(3, 3),
      const GridCell(3, 4),
      const GridCell(2, 4),
      const GridCell(2, 3)
    ];
    for (final grows in [false, true]) {
      final m = fixture([
        snake(0, body, Heading.left),
        snake(1, [const GridCell(9, 9)], Heading.left)
      ], growth: grows ? 1 : 100);
      m.stepSubstep();
      expect(m.snakes.first.alive, !grows);
    }
    final m = fixture([
      snake(0, body, Heading.down),
      snake(1, [const GridCell(9, 9)], Heading.left)
    ]);
    m.stepSubstep();
    expect(m.snakes.first.lossReason, 'body');
  });
  test('growth retains tail at configured cell cadence', () {
    final m = fixture([
      snake(0, [const GridCell(3, 3)], Heading.right),
      snake(1, [const GridCell(8, 8)], Heading.left)
    ], growth: 2);
    m.stepSubstep();
    expect(m.snakes.first.body.length, 1);
    m.stepSubstep();
    expect(m.snakes.first.body.length, 2);
  });
  test('dt partitions agree and invalid dt rejected', () {
    final a = RulesMatch(MatchConfig());
    final b = RulesMatch(MatchConfig());
    a.advance(1.5);
    for (var i = 0; i < 90; i++) b.advance(1 / 60);
    expect(a.tick, b.tick);
    expect(a.snakes.first.body, b.snakes.first.body);
    expect(() => a.advance(double.nan), throwsArgumentError);
  });
  test('2-4 snakes valid and tick limit is draw', () {
    for (var n = 2; n <= 4; n++) {
      final m = RulesMatch(MatchConfig(snakeCount: n, tickLimit: 1));
      m.stepSubstep();
      expect(m.snakes.length, n);
      expect(m.endReason, 'tick-limit');
      expect(m.winnerId, isNull);
    }
  });
  test('observation schema and free-space teacher deterministic', () {
    final m = RulesMatch(MatchConfig());
    expect(encodeObservation(m, 0).length, 252);
    expect(encodeObservation(m, 0).every((v) => v.isFinite), true);
    expect(const FreeSpaceBot().chooseDirection(m, 0),
        const FreeSpaceBot().chooseDirection(m, 0));
  });
}
