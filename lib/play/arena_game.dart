import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

typedef OpponentDecision = Heading Function(RulesMatch match, int snakeId);

/// Presentation adapter. Flame supplies all elapsed gameplay time.
class ArenaGame extends FlameGame {
  ArenaGame({
    required this.config,
    this.humanCount = 1,
    this.onChanged,
    OpponentDecision? decide,
  }) : decide = decide ?? const FreeSpaceBot().chooseDirection,
       match = RulesMatch(config) {
    _attachDecisions();
  }

  final MatchConfig config;
  final int humanCount;
  final void Function()? onChanged;
  final OpponentDecision decide;
  RulesMatch match;
  bool overloadPaused = false;
  final List<int> _decisionMicros = [];
  int? lastDecisionBatchP95Micros;
  void _attachDecisions() {
    match.beforeCellStep = (state) {
      final watch = Stopwatch()..start();
      final decisions = <int, Heading>{};
      for (final snake in state.snakes) {
        if (snake.id >= humanCount && snake.alive) {
          decisions[snake.id] = decide(state, snake.id);
        }
      }
      decisions.forEach(state.queueDirection);
      if (decisions.isNotEmpty) {
        _decisionMicros.add(watch.elapsedMicroseconds);
        if (_decisionMicros.length == 30) {
          final sorted = [..._decisionMicros]..sort();
          lastDecisionBatchP95Micros = sorted[28];
          debugPrint(
            'Atrapa boundary decisions: bots=${decisions.length}, n=30, p95=$lastDecisionBatchP95Micros us',
          );
          _decisionMicros.clear();
        }
      }
    };
  }

  void restart() {
    match = RulesMatch(config);
    overloadPaused = false;
    _attachDecisions();
    resumeEngine();
    onChanged?.call();
  }

  void direct(int player, Heading heading) {
    if (!paused && !match.isOver && player < humanCount) {
      match.queueDirection(player, heading);
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF121810);

  @override
  void update(double dt) {
    super.update(dt);
    if (paused || match.isOver) return;
    // Never turn a stalled/background frame into a burst of invisible moves.
    // Pause explicitly instead of dropping intermediate authoritative steps.
    if (dt > .5) {
      overloadPaused = true;
      pauseEngine();
      onChanged?.call();
      return;
    }
    final previousTick = match.tick;
    match.advance(dt);
    if (match.isOver) pauseEngine();
    if (match.tick != previousTick) onChanged?.call();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cell = size.x / config.width;
    final grid = Paint()
      ..color = const Color(0xFF263022)
      ..strokeWidth = .6;
    for (var x = 0; x <= config.width; x++) {
      canvas.drawLine(Offset(x * cell, 0), Offset(x * cell, size.y), grid);
    }
    for (var y = 0; y <= config.height; y++) {
      canvas.drawLine(Offset(0, y * cell), Offset(size.x, y * cell), grid);
    }
    const colors = [
      Color(0xFFB8ED75),
      Color(0xFF76BFF5),
      Color(0xFFF2A86E),
      Color(0xFFD59BF5),
    ];
    for (final snake in match.snakes) {
      final body = snake.body;
      final paint = Paint()
        ..color = colors[snake.id % colors.length].withValues(
          alpha: snake.alive ? 1 : .25,
        );
      for (var i = body.length - 1; i >= 0; i--) {
        final segment = body[i];
        final fraction = snake.alive
            ? snake.substep / config.substepsPerCell
            : 0.0;
        final ahead = i == 0 ? segment.moved(snake.heading) : body[i - 1];
        final px = segment.x + (ahead.x - segment.x) * fraction;
        final py = segment.y + (ahead.y - segment.y) * fraction;
        final rect = Rect.fromLTWH(
          px * cell + 1,
          py * cell + 1,
          cell - 2,
          cell - 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * .18)),
          paint,
        );
        if (i == 0) {
          final label = TextPainter(
            text: TextSpan(
              text: '${snake.id + 1}',
              style: TextStyle(
                color: const Color(0xFF10120F),
                fontSize: cell * .64,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(
            canvas,
            rect.center - Offset(label.width / 2, label.height / 2),
          );
        }
      }
    }
  }
}
