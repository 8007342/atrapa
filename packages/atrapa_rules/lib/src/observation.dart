import 'rules.dart';

const observationSchema = 'atrapa-grid-v1';
const observationSize = 252;
const policyActions = ['coast', 'left', 'right'];

/// Absolute board axes; a head-centered 9x9 map, row-major from (-4,-4).
/// Each tile: wall-or-body, other-head, free. Then heading up/right/down/left,
/// speed relative to 8 substeps/s, and up/right/down/left clear rays / board max.
/// Dead bodies stay occupied; outside cells are walls. No privileged future state.
List<double> encodeObservation(RulesMatch match, int snakeId) {
  final snake = match.snakes.firstWhere((s) => s.id == snakeId);
  final occupied = {for (final s in match.snakes) ...s.body};
  final otherHeads = {
    for (final s in match.snakes)
      if (s.id != snakeId && s.alive) s.head
  };
  bool inside(GridCell c) =>
      c.x >= 0 &&
      c.y >= 0 &&
      c.x < match.config.width &&
      c.y < match.config.height;
  bool blocked(GridCell c) => !inside(c) || occupied.contains(c);
  final result = <double>[];
  for (var y = -4; y <= 4; y++) {
    for (var x = -4; x <= 4; x++) {
      final c = GridCell(snake.head.x + x, snake.head.y + y);
      result.addAll([
        blocked(c) ? 1 : 0,
        otherHeads.contains(c) ? 1 : 0,
        blocked(c) ? 0 : 1
      ]);
    }
  }
  result.addAll(Heading.values.map((h) => h == snake.heading ? 1.0 : 0.0));
  result.add(match.config.substepsPerSecond / 8);
  final scale = match.config.width > match.config.height
      ? match.config.width
      : match.config.height;
  for (final h in Heading.values) {
    var c = snake.head.moved(h);
    var count = 0;
    while (!blocked(c)) {
      count++;
      c = c.moved(h);
    }
    result.add(count / scale);
  }
  return result;
}
