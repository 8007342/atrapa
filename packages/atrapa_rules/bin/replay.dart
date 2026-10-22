import 'dart:convert';
import 'dart:io';
import 'package:atrapa_rules/atrapa_rules.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run bin/replay.dart episode.json');
    exitCode = 64;
    return;
  }
  final replay = MatchReplay.fromJson(
    jsonDecode(File(args.single).readAsStringSync()) as Map<String, dynamic>,
  );
  final result = replay.run();
  stdout.writeln(jsonEncode({
    'rulesSchema': rulesSchemaVersion,
    'tick': result.tick,
    'winnerId': result.winnerId,
    'endReason': result.endReason,
    'snakes': [
      for (final s in result.snakes)
        {
          'id': s.id,
          'alive': s.alive,
          'lossReason': s.lossReason,
          'length': s.body.length
        }
    ],
  }));
}
