import 'package:atrapa/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('Construction screen fits a $width pixel viewport', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const AtrapaApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Under Construction'), findsOneWidget);
      expect(find.text('atrapa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
