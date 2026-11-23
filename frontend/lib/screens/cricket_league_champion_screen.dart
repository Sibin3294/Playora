import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/category_rating_prompt.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketLeagueChampionScreen extends StatefulWidget {
  const CricketLeagueChampionScreen({
    super.key,
    required this.competitionName,
    required this.franchise,
  });

  final String competitionName;
  final CricketTeam franchise;

  static Route<void> route({
    required String competitionName,
    required CricketTeam franchise,
  }) {
    return FadeScaleRoute(
      page: CricketLeagueChampionScreen(
        competitionName: competitionName,
        franchise: franchise,
      ),
    );
  }

  @override
  State<CricketLeagueChampionScreen> createState() =>
      _CricketLeagueChampionScreenState();
}

class _CricketLeagueChampionScreenState
    extends State<CricketLeagueChampionScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _confetti;
  late final AnimationController _popup;
  late final AnimationController _trophy;
  late final List<_PaperBit> _bits;
  int _popupIndex = -1;
  bool _showCongratsDialog = true;

  static const _popups = <_PopupLine>[
    _PopupLine('CONGRATULATIONS!', 'The cup is yours.'),
    _PopupLine('TITLE CLINCHED', 'League grind conquered.'),
    _PopupLine('CHAMPIONS OF THE NIGHT', 'Raise the bat high.'),
  ];

  @override
  void initState() {
    super.initState();
    final random = Random(42);
    _bits = List.generate(72, (_) => _PaperBit.random(random));

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _trophy = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _popup = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openCongratsDialog();
    });
  }

  Future<void> _openCongratsDialog() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'congrats',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondary) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.72, end: 1).animate(curved),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  decoration: panelDecoration(glow: GameColors.gold),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: GameColors.gold,
                        size: 52,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CONGRATULATIONS!',
                        textAlign: TextAlign.center,
                        style: hudLabelStyle(color: GameColors.gold, size: 14),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.franchise.name}\nare the champions!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameColors.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.competitionName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameColors.mute,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      NeonButton(
                        label: 'CELEBRATE',
                        color: GameColors.gold,
                        height: 48,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _showCongratsDialog = false);
    _trophy.forward();
    _runPopupSequence();
  }

  Future<void> _leave() async {
    if (mounted) {
      await maybePromptCategoryRating(context, 'sports');
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _runPopupSequence() async {
    for (var i = 0; i < _popups.length; i++) {
      if (!mounted) return;
      setState(() => _popupIndex = i);
      _popup
        ..reset()
        ..forward();
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      await _popup.reverse();
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted) return;
    setState(() => _popupIndex = -1);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _confetti.dispose();
    _popup.dispose();
    _trophy.dispose();
    super.dispose();
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
              animation: _confetti,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    bits: _bits,
                    t: _confetti.value,
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.competitionName.toUpperCase(),
                      style: hudLabelStyle(color: GameColors.gold, size: 12),
                    ),
                    const Spacer(),
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _trophy,
                        curve: Curves.elasticOut,
                      ),
                      child: FadeTransition(
                        opacity: _trophy,
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) {
                            final scale = 1 + (_pulse.value * 0.05);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration:
                                    panelDecoration(glow: GameColors.gold),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      color: GameColors.gold,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'CHAMPIONS',
                                      style: hudLabelStyle(
                                        color: GameColors.gold,
                                        size: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      widget.franchise.shortName,
                                      style: const TextStyle(
                                        color: GameColors.gold,
                                        fontSize: 52,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.franchise.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: GameColors.text,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'You drafted the XI, survived the league grind, and lifted the cup on the final night.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: GameColors.mute,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    NeonButton(
                      label: 'BACK TO THE PAVILION',
                      color: GameColors.gold,
                      onPressed: _leave,
                    ),
                  ],
                ),
              ),
            ),
            if (_popupIndex >= 0 && !_showCongratsDialog)
              Positioned(
                left: 20,
                right: 20,
                top: MediaQuery.paddingOf(context).top + 56,
                child: AnimatedBuilder(
                  animation: _popup,
                  builder: (context, _) {
                    final t = Curves.easeOutBack.transform(_popup.value);
                    final line = _popups[_popupIndex];
                    return Opacity(
                      opacity: _popup.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * -28),
                        child: Transform.scale(
                          scale: 0.9 + (0.1 * t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xEE1A1430),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: GameColors.gold,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: GameColors.gold.withOpacity(0.35),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  line.title,
                                  textAlign: TextAlign.center,
                                  style: hudLabelStyle(
                                    color: GameColors.gold,
                                    size: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  line.body,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: GameColors.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}

class _PopupLine {
  const _PopupLine(this.title, this.body);

  final String title;
  final String body;
}

class _PaperBit {
  _PaperBit({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.spin,
    required this.wobble,
    required this.rect,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double spin;
  final double wobble;
  final bool rect;

  factory _PaperBit.random(Random random) {
    const palette = <Color>[
      GameColors.gold,
      GameColors.cyan,
      GameColors.magenta,
      GameColors.lime,
      GameColors.coral,
      Color(0xFFFFF4C2),
      Color(0xFF8B5CFF),
    ];
    return _PaperBit(
      x: random.nextDouble(),
      delay: random.nextDouble(),
      speed: 0.35 + random.nextDouble() * 0.65,
      size: 5 + random.nextDouble() * 9,
      color: palette[random.nextInt(palette.length)],
      spin: (random.nextDouble() - 0.5) * 8,
      wobble: 12 + random.nextDouble() * 28,
      rect: random.nextBool(),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.bits, required this.t});

  final List<_PaperBit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final bit in bits) {
      var phase = (t * bit.speed + bit.delay) % 1.0;
      final y = -30 + phase * (size.height + 60);
      final x = bit.x * size.width +
          sin((t + bit.delay) * pi * 2 * bit.spin) * bit.wobble;
      final paint = Paint()..color = bit.color.withOpacity(0.88);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t + bit.delay) * bit.spin);
      if (bit.rect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: bit.size * 1.7,
              height: bit.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, bit.size * 0.45, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
