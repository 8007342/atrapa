import 'package:atrapa/main.dart';
import 'package:atrapa/play/play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final enabled in [false, true]) {
    testWidgets('Development play route enabled=$enabled', (tester) async {
      await tester.pumpWidget(AtrapaApp(enableDevPlay: enabled));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed('/play');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(PlayScreen), enabled ? findsOneWidget : findsNothing);
      if (!enabled) expect(find.text('Under Construction'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
