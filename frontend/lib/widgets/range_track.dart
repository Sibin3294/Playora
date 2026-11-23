import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/theme/game_theme.dart';

class RangeTrack extends StatelessWidget {
  const RangeTrack({super.key, required this.engine});

  final GuessEngine engine;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${engine.lowBound}',
                style: hudLabelStyle(color: GameColors.cyan)),
            Text(
              'SEARCH WINDOW',
              style: hudLabelStyle(size: 10),
            ),
            Text('${engine.highBound}',
                style: hudLabelStyle(color: GameColors.magenta)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 14,
          width: double.infinity,
          child: CustomPaint(
            painter: _RangePainter(engine: engine),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _RangePainter extends CustomPainter {
  const _RangePainter({required this.engine});

  final GuessEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromLTRBR(
      0,
      4,
      size.width,
      size.height - 4,
      const Radius.circular(8),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFF222A4D));

    double xFor(int value) {
      final span = max(1, engine.maxValue - engine.minValue);
      return ((value - engine.minValue) / span) * size.width;
    }

    final left = xFor(engine.lowBound);
    final right = xFor(engine.highBound);
    final window = RRect.fromLTRBR(
      left,
      2,
      right,
      size.height - 2,
      const Radius.circular(8),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..shader = const LinearGradient(
          colors: [GameColors.cyan, GameColors.magenta],
        ).createShader(Rect.fromLTWH(
            left, 0, (right - left).clamp(4, size.width), size.height)),
    );

    for (final guess in engine.guesses) {
      final x = xFor(guess.value);
      canvas.drawCircle(
        Offset(x, size.height / 2),
        3.2,
        Paint()..color = GameColors.gold,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RangePainter oldDelegate) => true;
}
