import 'rules.dart';

/// Bounded flood-fill teacher. Deterministic ties vary by seed, tick and snake.
class FreeSpaceBot {
  const FreeSpaceBot({this.radius = 6});
  final int radius;

  Heading chooseDirection(RulesMatch match, int snakeId) {
    final snake = match.snakes.firstWhere((s) => s.id == snakeId);
    final occupied = {for (final s in match.snakes) ...s.body};
    bool free(GridCell c) =>
        c.x >= 0 &&
        c.y >= 0 &&
        c.x < match.config.width &&
        c.y < match.config.height &&
        !occupied.contains(c);
    final directions =
        Heading.values.where((h) => h != snake.heading.opposite).toList();
    var best = -1;
    final choices = <Heading>[];
    for (final direction in directions) {
      final start = snake.head.moved(direction);
      var score = 0;
      if (free(start)) {
        final seen = <GridCell>{start};
        final queue = <GridCell>[start];
        for (var i = 0; i < queue.length; i++) {
          for (final h in Heading.values) {
            final next = queue[i].moved(h);
            if (next.distanceTo(start) <= radius &&
                free(next) &&
                seen.add(next)) queue.add(next);
          }
        }
        score = seen.length;
      }
      if (score > best) {
        best = score;
        choices.clear();
      }
      if (score == best) choices.add(direction);
    }
    var state =
        (match.config.seed ^ (match.tick * 1103515245) ^ (snakeId * 12345)) &
            0x7fffffff;
    state = (state * 1664525 + 1013904223) & 0x7fffffff;
    return choices[state % choices.length];
  }
}
