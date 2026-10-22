import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:test/test.dart';

// FNV-1a over canonical integer-only snapshots; never use VM-dependent hashCode.
String replayDigest() {
  final match =
      RulesMatch(MatchConfig(seed: 1724, snakeCount: 4, tickLimit: 600));
  var hash = 0x811c9dc5;
  void append(String text) {
    for (final byte in text.codeUnits) {
      final value = hash ^ byte;
      hash = ((value & 0xffff) * 0x01000193 +
              (((value >> 16) * 0x0193 & 0xffff) << 16)) &
          0xffffffff;
    }
  }

  match.beforeCellStep = (m) {
    final decisions = {
      for (final s in m.snakes.where((s) => s.alive))
        s.id: const FreeSpaceBot().chooseDirection(m, s.id)
    };
    for (final decision in decisions.entries) {
      m.queueDirection(decision.key, decision.value);
    }
  };
  append('$rulesSchemaVersion|seed=1724;');
  while (!match.isOver) {
    match.stepSubstep();
    append('${match.tick}:');
    for (final s in match.snakes) {
      append(
          '${s.id},${s.heading.index},${s.alive},${s.lossReason},${s.substep}:');
      for (final c in s.body) {
        append('${c.x},${c.y};');
      }
    }
  }
  append('${match.winnerId}/${match.endReason}');
  return hash.toRadixString(16).padLeft(8, '0');
}

void main() {
  test('schema v1 golden seed and teacher-command replay', () {
    expect(replayDigest(), '57682a43');
  });
}
