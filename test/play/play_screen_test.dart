import 'package:atrapa/play/arena_game.dart';
import 'package:atrapa/play/play_screen.dart';
import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'long frame pauses explicitly without advancing or skipping collisions',
    () {
      final game = ArenaGame(config: MatchConfig());
      game.update(1);
      expect(game.paused, true);
      expect(game.overloadPaused, true);
      expect(game.match.tick, 0);
    },
  );

  test(
    'finished match pauses Flame and leaves authoritative outcome intact',
    () {
      final game = ArenaGame(config: MatchConfig(tickLimit: 2));
      game.update(.25);
      expect(game.match.isOver, true);
      expect(game.paused, true);
      expect(game.match.endReason, 'tick-limit');
    },
  );

  testWidgets(
    'async policy changes apply without replacing the running match',
    (tester) async {
      final loaded = ValueNotifier<bool>(false);
      addTearDown(loaded.dispose);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: loaded,
            builder: (_, ready, child) => PlayScreen(
              policyLabel: ready ? 'Policy test' : 'Baseline opponents',
              decide: ready
                  ? (state, id) {
                      calls++;
                      return state.snakes[id].heading;
                    }
                  : null,
            ),
          ),
        ),
      );
      await tester.pump();
      final game = tester
          .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
          .game!;
      final originalMatch = game.match;
      game.match.stepSubstep();
      final originalTick = game.match.tick;
      loaded.value = true;
      await tester.pump();
      expect(find.text('Policy test · development preview'), findsOneWidget);
      expect(
        tester
            .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
            .game,
        same(game),
      );
      expect(game.match, same(originalMatch));
      expect(game.match.tick, originalTick);
      for (var i = 0; i < 4; i++) {
        game.match.stepSubstep();
      }
      expect(calls, 1);
      loaded.value = false;
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        game.match.stepSubstep();
      }
      expect(calls, 1);
      expect(game.match, same(originalMatch));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('portrait controls fit, pause freezes state and restart resets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: PlayScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final game = tester
        .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
        .game!;
    await tester.tap(find.text('Pause'));
    await tester.pump();
    final tick = game.match.tick;
    await tester.pump(const Duration(seconds: 1));
    expect(game.match.tick, tick);
    expect(game.paused, isTrue);
    await tester.tap(find.text('Restart'));
    await tester.pump();
    final restarted = tester
        .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
        .game!;
    expect(restarted.match.tick, 0);
    expect(restarted.paused, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('two-human keyboard maps WASD and arrows to separate snakes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PlayScreen()));
    await tester.pump();
    await tester.tap(find.text('Solo'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Two humans').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final game = tester
        .widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>))
        .game!;
    expect(game.humanCount, 2);
    expect(game.config.snakeCount, 2);
    expect(find.text('0 AI'), findsOneWidget);
    expect(game.paused, false);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    for (var i = 0; i < 4; i++) {
      game.match.stepSubstep();
    }
    expect(game.match.snakes[0].heading, Heading.up);
    expect(game.match.snakes[1].heading, Heading.left);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    for (var i = 0; i < 4; i++) {
      game.match.stepSubstep();
    }
    expect(game.match.snakes[1].heading, Heading.down);
    expect(game.match.snakes[0].heading, Heading.up);
    await tester.pumpWidget(const SizedBox());
  });
}
