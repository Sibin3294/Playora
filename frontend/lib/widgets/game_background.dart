import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/theme/game_theme.dart';

class GameBackground extends StatefulWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final random = Random(7);
    _stars = List.generate(70, (index) {
      return _Star(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        radius: 0.6 + random.nextDouble() * 1.7,
        phase: random.nextDouble() * pi * 2,
        speed: 0.6 + random.nextDouble() * 1.8,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GameColors.voidBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.65),
                radius: 1.15,
                colors: [
                  Color(0xFF2A1258),
                  Color(0xFF0C1230),
                  GameColors.voidBg,
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarfieldPainter(
                  stars: _stars,
                  t: _controller.value * 2 * pi,
                ),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x66050713),
                ],
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
    required this.speed,
  });

  final double dx;
  final double dy;
  final double radius;
  final double phase;
  final double speed;
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter({required this.stars, required this.t});

  final List<_Star> stars;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * sin(t * star.speed + star.phase));
      paint.color = Colors.white.withOpacity(twinkle);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.t != t;
}
