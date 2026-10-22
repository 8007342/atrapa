import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arena_game.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    this.decide,
    this.policyLabel = 'Baseline opponents',
    this.policyDetail,
  });
  final OpponentDecision? decide;
  final String policyLabel;
  final String? policyDetail;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver {
  final _focus = FocusNode(debugLabel: 'arena controls');
  late ArenaGame _game;
  int _humans = 1;
  int _opponents = 1;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createGame();
  }

  void _createGame() {
    _game = ArenaGame(
      config: MatchConfig(
        snakeCount: _humans + _opponents,
        substepsPerSecond: 6.0 + _level * 2,
      ),
      humanCount: _humans,
      // Read the latest widget callback: policy loading/fallback may finish
      // after the match starts and must not require resetting the match.
      decide: (state, id) =>
          widget.decide?.call(state, id) ??
          const FreeSpaceBot().chooseDirection(state, id),
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _game.pauseEngine();
      if (mounted) setState(() {});
    }
  }

  void _reset() {
    _game.pauseEngine();
    setState(_createGame);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final arrows = {
      LogicalKeyboardKey.arrowUp: Heading.up,
      LogicalKeyboardKey.arrowRight: Heading.right,
      LogicalKeyboardKey.arrowDown: Heading.down,
      LogicalKeyboardKey.arrowLeft: Heading.left,
    };
    final wasd = {
      LogicalKeyboardKey.keyW: Heading.up,
      LogicalKeyboardKey.keyD: Heading.right,
      LogicalKeyboardKey.keyS: Heading.down,
      LogicalKeyboardKey.keyA: Heading.left,
    };
    final arrow = arrows[event.logicalKey];
    final letter = wasd[event.logicalKey];
    if (arrow != null) {
      _game.direct(_humans == 2 ? 1 : 0, arrow);
      return KeyEventResult.handled;
    }
    if (letter != null && _humans == 2) {
      _game.direct(0, letter);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _pause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _pause() => setState(() {
    if (_game.match.isOver) return;
    if (_game.paused) {
      _game.overloadPaused = false;
      _game.resumeEngine();
    } else {
      _game.pauseEngine();
    }
  });

  Widget _direction(Heading heading, IconData icon) => SizedBox(
    width: 56,
    height: 48,
    child: IconButton.filledTonal(
      tooltip: heading.name,
      onPressed: () {
        _game.direct(0, heading);
        _focus.requestFocus();
      },
      icon: Icon(icon),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF10120F),
    body: SafeArea(
      child: Focus(
        autofocus: true,
        focusNode: _focus,
        onKeyEvent: _key,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final boardHeight = (bounds.maxHeight - 290).clamp(160.0, 640.0);
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Text(
                              'atrapa',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB8ED75),
                              ),
                            ),
                            Spacer(),
                            Text(
                              'PLAY LAB',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DropdownButton<int>(
                              value: _humans,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Solo')),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Two humans'),
                                ),
                              ],
                              onChanged: (v) {
                                _humans = v!;
                                _opponents = _humans == 2 ? 0 : 1;
                                _reset();
                              },
                            ),
                            DropdownButton<int>(
                              value: _opponents,
                              items: [
                                for (
                                  var n = _humans == 2 ? 0 : 1;
                                  n <= (_humans == 2 ? 2 : 3);
                                  n++
                                )
                                  DropdownMenuItem(
                                    value: n,
                                    child: Text('$n AI'),
                                  ),
                              ],
                              onChanged: (v) {
                                _opponents = v!;
                                _reset();
                              },
                            ),
                            DropdownButton<int>(
                              value: _level,
                              items: [
                                for (var n = 1; n <= 3; n++)
                                  DropdownMenuItem(
                                    value: n,
                                    child: Text('Speed $n'),
                                  ),
                              ],
                              onChanged: (v) {
                                _level = v!;
                                _reset();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox.square(
                          dimension: boardHeight.clamp(0, bounds.maxWidth - 32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GameWidget(
                              key: ObjectKey(_game),
                              game: _game,
                              autofocus: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _game.match.isOver
                              ? (_game.match.winnerId == null
                                    ? 'Draw — try again'
                                    : 'Snake ${_game.match.winnerId! + 1} wins')
                              : _game.paused
                              ? (_game.overloadPaused
                                    ? 'Frame delay — paused safely'
                                    : 'Paused')
                              : 'Stay moving. Find your opening.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB8ED75),
                          ),
                        ),
                        for (final snake in _game.match.snakes)
                          if (!snake.alive)
                            Text(
                              'Snake ${snake.id + 1}: ${snake.lossReason ?? "eliminated"}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _game.match.isOver ? null : _pause,
                              icon: Icon(
                                _game.paused ? Icons.play_arrow : Icons.pause,
                              ),
                              label: Text(_game.paused ? 'Resume' : 'Pause'),
                            ),
                            TextButton.icon(
                              onPressed: _reset,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Restart'),
                            ),
                          ],
                        ),
                        _direction(Heading.up, Icons.arrow_upward),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _direction(Heading.left, Icons.arrow_back),
                            const SizedBox(width: 8),
                            _direction(Heading.down, Icons.arrow_downward),
                            const SizedBox(width: 8),
                            _direction(Heading.right, Icons.arrow_forward),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _humans == 2
                              ? 'P1 lime: WASD / touch · P2 blue: arrows'
                              : 'Arrow keys or touch · Space to pause',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${widget.policyLabel} · development preview',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                        if (widget.policyDetail != null)
                          Text(
                            widget.policyDetail!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
