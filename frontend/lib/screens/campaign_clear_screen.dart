import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/screens/history_screen.dart';
import 'package:guess_game/screens/play_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/category_rating_prompt.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CampaignClearScreen extends StatefulWidget {
  const CampaignClearScreen({
    super.key,
    required this.engine,
    required this.level,
    required this.points,
    required this.totalPoints,
    required this.bonus,
    this.archive,
  });

  final GuessEngine engine;
  final HuntLevel level;
  final int points;
  final int totalPoints;
  final int bonus;
  final HuntArchive? archive;

  @override
  State<CampaignClearScreen> createState() => _CampaignClearScreenState();
}

class _CampaignClearScreenState extends State<CampaignClearScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _burst;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final random = Random(21);
    _sparks = List.generate(36, (index) {
      return _Spark(
        dx: random.nextDouble(),
        angle: (index / 36) * pi * 2 + random.nextDouble() * 0.4,
        speed: 0.18 + random.nextDouble() * 0.55,
        size: 3.0 + random.nextDouble() * 5.0,
        color: [
          GameColors.gold,
          GameColors.cyan,
          GameColors.magenta,
          GameColors.lime,
          GameColors.violet,
        ][index % 5],
      );
    });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  Future<void> _afterWinLeave(VoidCallback next) async {
    if (mounted) {
      await maybePromptCategoryRating(context, 'number');
    }
    if (!mounted) return;
    next();
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SparkPainter(
                    sparks: _sparks,
                    t: _burst.value,
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  children: [
                    Text(
                      'CAMPAIGN COMPLETE',
                      style: hudLabelStyle(color: GameColors.gold, size: 12),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, child) {
                                final glow = 22 + (_pulse.value * 28);
                                return Container(
                                  width: 176,
                                  height: 176,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFE08A),
                                        Color(0xFFFF3CAC),
                                        Color(0xFF140B2E),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: GameColors.gold,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            GameColors.gold.withOpacity(0.55),
                                        blurRadius: glow,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: GameColors.magenta
                                            .withOpacity(0.35),
                                        blurRadius: glow + 16,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                size: 84,
                                color: Color(0xFF071018),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'LEGEND',
                              style: TextStyle(
                                color: GameColors.gold,
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You cleared every hunt.\nThe last number could not hide.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameColors.text,
                                fontSize: 16,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final level in HuntLevel.all)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(99),
                                      color: level.accent.withOpacity(0.16),
                                      border: Border.all(color: level.accent),
                                    ),
                                    child: Text(
                                      '✓  ${level.name}',
                                      style: hudLabelStyle(
                                        color: level.accent,
                                        size: 9,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: panelDecoration(
                                border: GameColors.gold,
                                glow: GameColors.gold,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'PHANTOM NUMBER',
                                    style:
                                        hudLabelStyle(color: GameColors.gold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${widget.engine.secretNumber}',
                                    style: const TextStyle(
                                      color: GameColors.text,
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  Text(
                                    'Cracked in ${widget.engine.attemptsUsed} of ${widget.engine.maxAttempts} shots',
                                    style: const TextStyle(
                                      color: GameColors.mute,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '+${widget.points} PTS',
                                    style: const TextStyle(
                                      color: GameColors.gold,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  if (widget.bonus > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'CAMPAIGN BONUS +${widget.bonus}',
                                      style: hudLabelStyle(
                                        color: GameColors.lime,
                                        size: 11,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    '${widget.totalPoints} TOTAL POINTS',
                                    style: const TextStyle(
                                      color: GameColors.mute,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'A true hunter does not stop. Run the grid again, or rest as a legend.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameColors.mute,
                                height: 1.45,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    NeonButton(
                      label: 'PLAY PHANTOM AGAIN',
                      color: GameColors.gold,
                      onPressed: () => _afterWinLeave(() {
                        Navigator.of(context).pushReplacement(
                          PlayScreen.route(level: widget.level),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _afterWinLeave(() {
                        Navigator.of(context).push(
                          HistoryScreen.route(archive: widget.archive),
                        );
                      }),
                      child: Text(
                        'VIEW HUNT LOG',
                        style: hudLabelStyle(color: GameColors.cyan),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _afterWinLeave(() => Navigator.of(context).pop()),
                      child: Text(
                        'BACK TO BASE',
                        style: hudLabelStyle(color: GameColors.mute),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spark {
  const _Spark({
    required this.dx,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  final double dx;
  final double angle;
  final double speed;
  final double size;
  final Color color;
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.sparks, required this.t});

  final List<_Spark> sparks;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.28);
    for (final spark in sparks) {
      final travel = (t + spark.dx) % 1.0;
      final radius = travel * min(size.width, size.height) * spark.speed * 1.4;
      final offset = Offset(
        origin.dx + cos(spark.angle) * radius,
        origin.dy + sin(spark.angle) * radius * 0.85,
      );
      final paint = Paint()
        ..color = spark.color.withOpacity((1 - travel) * 0.9);
      canvas.drawCircle(offset, spark.size * (1 - travel * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.t != t;
}
