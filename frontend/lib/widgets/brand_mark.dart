import 'package:flutter/material.dart';
import 'package:guess_game/theme/game_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 120,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: GameColors.cyan.withOpacity(0.35),
                  blurRadius: size * 0.28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: GameColors.magenta.withOpacity(0.22),
                  blurRadius: size * 0.36,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/branding/playora_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: GameColors.deep,
            alignment: Alignment.center,
            child: Text(
              'P',
              style: TextStyle(
                color: GameColors.cyan,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
