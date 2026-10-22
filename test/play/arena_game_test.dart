import 'dart:convert';
import 'dart:io';

import 'package:atrapa/play/arena_game.dart';
import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('committed episode matches rules and Flame adapter', () {
    final json = jsonDecode(
      File('packages/atrapa_rules/test/fixtures/golden_episode.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final replay = MatchReplay.fromJson(json);
    final game = ArenaGame(
      config: replay.config,
      humanCount: replay.config.snakeCount,
    );
    var cursor = 0;
    while (!game.match.isOver) {
      while (cursor < replay.commands.length &&
          replay.commands[cursor].tick == game.match.tick) {
        final command = replay.commands[cursor++];
        game.direct(command.snakeId, command.heading);
      }
      game.update(1 / replay.config.substepsPerSecond);
    }
    final result = game.match;
    final actual = {
      'tick': result.tick,
      'winnerId': result.winnerId,
      'endReason': result.endReason,
      'snakes': [
        for (final s in result.snakes)
          {
            'id': s.id,
            'heading': s.heading.name,
            'alive': s.alive,
            'lossReason': s.lossReason,
            'body': [
              for (final c in s.body) [c.x, c.y],
            ],
          },
      ],
    };
    expect(actual, json['expected']);
    expect(game.paused, isTrue);
  });
}
