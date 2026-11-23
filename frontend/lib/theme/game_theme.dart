import 'package:flutter/material.dart';

class GameColors {
  static const voidBg = Color(0xFF050713);
  static const deep = Color(0xFF0B1024);
  static const panel = Color(0xCC141A33);
  static const panelSolid = Color(0xFF141A33);
  static const panelBorder = Color(0xFF33407A);
  static const cyan = Color(0xFF33F0FF);
  static const magenta = Color(0xFFFF3CAC);
  static const violet = Color(0xFF8B5CFF);
  static const gold = Color(0xFFFFD166);
  static const lime = Color(0xFF7CFF6B);
  static const coral = Color(0xFFFF5D73);
  static const text = Color(0xFFF4F7FF);
  static const mute = Color(0xFF9AA3C7);
}

class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute({required Widget page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}

BoxDecoration panelDecoration({Color? border, Color? glow}) {
  return BoxDecoration(
    color: GameColors.panel,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: border ?? GameColors.panelBorder, width: 1.4),
    boxShadow: [
      BoxShadow(
        color: (glow ?? GameColors.violet).withOpacity(0.18),
        blurRadius: 28,
        spreadRadius: 1,
      ),
    ],
  );
}

TextStyle hudLabelStyle({double size = 11, Color color = GameColors.mute}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.4,
  );
}
