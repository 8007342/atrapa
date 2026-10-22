/// Increment when rules or observation semantics change; retrain exported policies.
const rulesSchemaVersion = 'atrapa-rules-v1';

enum Heading {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const Heading(this.dx, this.dy);
  final int dx;
  final int dy;
  Heading get opposite => Heading.values[(index + 2) % 4];
  bool perpendicularTo(Heading other) => dx * other.dx + dy * other.dy == 0;
}

class GridCell {
  const GridCell(this.x, this.y);
  final int x;
  final int y;
  GridCell moved(Heading heading) => GridCell(x + heading.dx, y + heading.dy);
  int distanceTo(GridCell other) => (x - other.x).abs() + (y - other.y).abs();
  @override
  bool operator ==(Object other) =>
      other is GridCell && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
  @override
  String toString() => '$x,$y';
}

class MatchConfig {
  MatchConfig(
      {this.width = 16,
      this.height = 16,
      this.substepsPerCell = 4,
      this.substepsPerSecond = 8,
      this.initialLength = 3,
      this.growthEveryCells = 6,
      this.tickLimit = 2400,
      this.snakeCount = 2,
      this.seed = 42}) {
    if (width < 6 ||
        height < 6 ||
        substepsPerCell < 1 ||
        !substepsPerSecond.isFinite ||
        substepsPerSecond <= 0 ||
        initialLength < 1 ||
        initialLength > (width < height ? width : height) ~/ 2 ||
        growthEveryCells < 1 ||
        tickLimit < 1 ||
        snakeCount < 2 ||
        snakeCount > 4) {
      throw ArgumentError('Invalid grid match configuration');
    }
  }
  final int width,
      height,
      substepsPerCell,
      initialLength,
      growthEveryCells,
      tickLimit,
      snakeCount,
      seed;
  final double substepsPerSecond;
}

class SnakeState {
  SnakeState(
      {required this.id,
      required List<GridCell> body,
      required this.heading,
      this.alive = true,
      this.lossReason,
      int substep = 0,
      int cellsTravelled = 0})
      : _body = List.of(body),
        _substep = substep,
        _cellsTravelled = cellsTravelled {
    if (body.isEmpty) throw ArgumentError('Snake needs a body');
  }
  final int id;
  final List<GridCell> _body;
  List<GridCell> get body => List.unmodifiable(_body);
  GridCell get head => _body.first;
  Heading heading;
  bool alive;
  String? lossReason;
  int _substep;
  int get substep => _substep;
  int _cellsTravelled;
  Heading? _pending;
}

/// A deterministic state machine. It never starts a clock: the host supplies dt.
/// Distinct non-growing tails vacate simultaneously even on elimination.
/// Sole heads remain occupied; dead bodies retain all other segments.
class RulesMatch {
  RulesMatch(this.config) : _snakes = _initialSnakes(config);

  /// Fixture/replay entry point. Takes defensive copies of snake bodies.
  RulesMatch.fromState(this.config, List<SnakeState> snakes, {this.tick = 0})
      : _snakes = snakes
            .map((s) => SnakeState(
                id: s.id,
                body: s.body,
                heading: s.heading,
                alive: s.alive,
                lossReason: s.lossReason,
                substep: s.substep,
                cellsTravelled: s._cellsTravelled))
            .toList() {
    if (snakes.length != config.snakeCount ||
        snakes.map((s) => s.id).toSet().length != snakes.length) {
      throw ArgumentError('Fixture snake count/IDs do not match configuration');
    }
  }
  final MatchConfig config;
  final List<SnakeState> _snakes;
  List<SnakeState> get snakes => List.unmodifiable(_snakes);
  int tick = 0;
  bool isOver = false;
  int? winnerId;
  String? endReason;
  double _accumulator = 0;
  void Function(RulesMatch)? beforeCellStep;

  static List<SnakeState> _initialSnakes(MatchConfig c) {
    final positions = <(GridCell, Heading)>[
      (GridCell(c.initialLength - 1, c.height ~/ 3), Heading.right),
      (GridCell(c.width - c.initialLength, 2 * c.height ~/ 3), Heading.left),
      (GridCell(2 * c.width ~/ 3, c.initialLength - 1), Heading.down),
      (GridCell(c.width ~/ 3, c.height - c.initialLength), Heading.up),
    ];
    return List.generate(c.snakeCount, (id) {
      final (head, heading) = positions[id];
      return SnakeState(
          id: id,
          heading: heading,
          body: List.generate(
              c.initialLength,
              (i) =>
                  GridCell(head.x - heading.dx * i, head.y - heading.dy * i)));
    });
  }

  void queueDirection(int snakeId, Heading direction) {
    final snake = _snakes.where((s) => s.id == snakeId).firstOrNull;
    if (snake == null) throw ArgumentError.value(snakeId, 'snakeId');
    if (!isOver && snake.alive && direction.perpendicularTo(snake.heading)) {
      snake._pending = direction;
    }
  }

  void advance(double dt) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    if (isOver) return;
    _accumulator += dt * config.substepsPerSecond;
    while (_accumulator + 1e-9 >= 1 && !isOver) {
      _accumulator -= 1;
      stepSubstep();
    }
  }

  void stepSubstep() {
    if (isOver) return;
    tick++;
    if (_snakes.any((s) => s.alive && s._substep == 0))
      beforeCellStep?.call(this);
    final living = _snakes.where((s) => s.alive).toList();
    for (final snake in living) {
      // A turn at substep zero starts movement toward the next cell.
      if (snake._substep == 0 && snake._pending != null) {
        snake.heading = snake._pending!;
        snake._pending = null;
      }
      snake._substep++;
    }
    final moving =
        living.where((s) => s._substep >= config.substepsPerCell).toList();
    if (moving.isNotEmpty) _move(moving);
    final survivors = _snakes.where((s) => s.alive).toList();
    if (survivors.length <= 1) {
      isOver = true;
      winnerId = survivors.firstOrNull?.id;
      endReason = survivors.isEmpty ? 'all-eliminated' : 'last-survivor';
    } else if (tick >= config.tickLimit) {
      isOver = true;
      endReason = 'tick-limit';
    }
  }

  void _move(List<SnakeState> moving) {
    final targets = {for (final s in moving) s.id: s.head.moved(s.heading)};
    final growing = {
      for (final s in moving)
        s.id: (s._cellsTravelled + 1) % config.growthEveryCells == 0
    };
    final occupied = <GridCell>{};
    for (final s in _snakes) {
      // Bodies remain obstacles after elimination.
      final vacates =
          targets.containsKey(s.id) && !growing[s.id]! && s._body.length > 1;
      occupied.addAll(s._body.take(s._body.length - (vacates ? 1 : 0)));
    }
    final losses = <int, String>{};
    for (final s in moving) {
      final target = targets[s.id]!;
      if (target.x < 0 ||
          target.y < 0 ||
          target.x >= config.width ||
          target.y >= config.height) {
        losses[s.id] = 'wall';
      } else if (occupied.contains(target)) {
        losses[s.id] = 'body';
      }
      for (final other in moving) {
        if (s.id == other.id) continue;
        if (target == targets[other.id] ||
            (target == other.head && targets[other.id] == s.head)) {
          losses[s.id] = 'head-on';
        }
      }
    }
    for (final s in moving) {
      s._substep = 0;
      if (losses.containsKey(s.id)) {
        // Projected non-growing tails vacate even when their head is lost.
        if (!growing[s.id]! && s._body.length > 1) s._body.removeLast();
        s.alive = false;
        s.lossReason = losses[s.id];
      } else {
        s._body.insert(0, targets[s.id]!);
        if (!growing[s.id]!) s._body.removeLast();
        s._cellsTravelled++;
      }
    }
  }
}
