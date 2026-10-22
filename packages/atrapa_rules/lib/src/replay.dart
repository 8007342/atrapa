import 'rules.dart';

/// Input applied before advancing [tick] (zero-based elapsed substep index).
class ReplayCommand {
  const ReplayCommand(this.tick, this.snakeId, this.heading);
  final int tick;
  final int snakeId;
  final Heading heading;
  Map<String, Object> toJson() =>
      {'tick': tick, 'snakeId': snakeId, 'heading': heading.name};
  factory ReplayCommand.fromJson(Map<String, dynamic> json) => ReplayCommand(
      json['tick'] as int,
      json['snakeId'] as int,
      Heading.values.byName(json['heading'] as String));
}

/// Portable seed/config + ordered input trace. No rendering or model is needed
/// to replay an episode. Same-tick commands retain list order (latest wins).
class MatchReplay {
  MatchReplay(this.config, List<ReplayCommand> commands)
      : commands = List.unmodifiable(commands) {
    var previous = -1;
    for (final command in commands) {
      if (command.tick < previous ||
          command.tick < 0 ||
          command.snakeId < 0 ||
          command.snakeId >= config.snakeCount) {
        throw ArgumentError('Invalid or unsorted replay command');
      }
      previous = command.tick;
    }
  }
  final MatchConfig config;
  final List<ReplayCommand> commands;
  Map<String, Object> toJson() => {
        'rulesSchema': rulesSchemaVersion,
        'config': {
          'width': config.width,
          'height': config.height,
          'substepsPerCell': config.substepsPerCell,
          'substepsPerSecond': config.substepsPerSecond,
          'initialLength': config.initialLength,
          'growthEveryCells': config.growthEveryCells,
          'tickLimit': config.tickLimit,
          'snakeCount': config.snakeCount,
          'seed': config.seed,
        },
        'commands': commands.map((c) => c.toJson()).toList(),
      };
  factory MatchReplay.fromJson(Map<String, dynamic> json) {
    if (json['rulesSchema'] != rulesSchemaVersion)
      throw FormatException('Unsupported rules schema');
    final c = json['config'] as Map<String, dynamic>;
    return MatchReplay(
        MatchConfig(
            width: c['width'] as int,
            height: c['height'] as int,
            substepsPerCell: c['substepsPerCell'] as int,
            substepsPerSecond: (c['substepsPerSecond'] as num).toDouble(),
            initialLength: c['initialLength'] as int,
            growthEveryCells: c['growthEveryCells'] as int,
            tickLimit: c['tickLimit'] as int,
            snakeCount: c['snakeCount'] as int,
            seed: c['seed'] as int),
        (json['commands'] as List)
            .map((v) => ReplayCommand.fromJson(v as Map<String, dynamic>))
            .toList());
  }
  RulesMatch run() {
    final match = RulesMatch(config);
    var cursor = 0;
    while (!match.isOver) {
      while (cursor < commands.length && commands[cursor].tick == match.tick) {
        final command = commands[cursor++];
        match.queueDirection(command.snakeId, command.heading);
      }
      match.stepSubstep();
    }
    return match;
  }
}
