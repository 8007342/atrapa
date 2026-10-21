import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';

/// Decorative Flame canvas; gameplay will be introduced through future specs.
class AtrapaGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF10120F);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final grid = Paint()
      ..color = const Color(0xFF20251D)
      ..strokeWidth = .6;
    for (double x = 0; x < size.x; x += 56) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), grid);
    }
    for (double y = 0; y < size.y; y += 56) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), grid);
    }
    final ring = Paint()
      ..color = const Color(0xFFB8ED75).withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.x * .5, size.y * .46);
    final radius = math.min(size.x * .44, 310.0);
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(
      center,
      radius + 24,
      ring..color = const Color(0xFFB8ED75).withValues(alpha: .05),
    );
    final dot = Paint()..color = const Color(0xFFB8ED75);
    canvas.drawCircle(
      Offset(center.dx + radius * .72, center.dy - radius * .69),
      5,
      dot,
    );
    canvas.drawCircle(
      Offset(center.dx - radius * .91, center.dy + radius * .41),
      3,
      dot..color = const Color(0xFFB8ED75).withValues(alpha: .5),
    );
  }
}
