import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/atrapa_game.dart';

void main() => runApp(const AtrapaApp());

class AtrapaApp extends StatelessWidget {
  const AtrapaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Atrapa — Under Construction',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const ConstructionScreen(),
  );
}

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  final _game = AtrapaGame();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF10120F),
    body: Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(child: GameWidget(game: _game)),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 24 : 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 20,
                          runSpacing: 12,
                          children: [
                            const Text(
                              'TLATOĀNI',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'IN THE MAKING',
                              style: TextStyle(
                                color: Colors.white54,
                                letterSpacing: 2,
                                fontSize: compact ? 9 : 11,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 100 : 110),
                        Center(
                          child: FittedBox(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFB8ED75)
                                      .withValues(alpha: .4),
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'A NEW CHAPTER IS LOADING',
                                style: TextStyle(
                                  color: Color(0xFFB8ED75),
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'atrapa',
                              style: TextStyle(
                                fontSize: compact ? 100 : 172,
                                height: 1.05,
                                letterSpacing: -9,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF4F1E8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Under Construction',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF4F1E8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'An old favorite. A new adventure.\nWe’re getting things ready for you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            width: 180,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB8ED75),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'GOOD THINGS TAKE A LITTLE PLAY.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            letterSpacing: 2,
                            fontSize: 9,
                          ),
                        ),
                        SizedBox(height: compact ? 100 : 110),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 14,
                          spacing: 24,
                          children: const [
                            Text(
                              'A homage to Atrapa, by Bulloncito.',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'WEB / MOBILE / DESKTOP',
                              style: TextStyle(
                                color: Colors.white38,
                                letterSpacing: 2,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
