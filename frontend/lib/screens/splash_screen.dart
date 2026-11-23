import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/branding/app_brand.dart';
import 'package:guess_game/screens/auth_gate.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/brand_mark.dart';
import 'package:guess_game/widgets/game_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _pulse;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1, curve: Curves.easeInOut),
      ),
    );

    if (!GameSession.forceLocal) {
      _advanceTimer = Timer(widget.duration, _openApp);
    }
  }

  void _openApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (GameSession.forceLocal) {
      return const AuthGate();
    }

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: _pulse.value,
                          child: const BrandMark(size: 128),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          AppBrand.shortTag,
                          style: TextStyle(
                            color: GameColors.cyan.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                        const Text(
                          AppBrand.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GameColors.text,
                            fontSize: 52,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppBrand.tagline.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: hudLabelStyle(
                            color: GameColors.gold.withOpacity(0.9),
                            size: 10,
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: 148,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _controller.value,
                              minHeight: 3,
                              backgroundColor: GameColors.panelBorder,
                              color: GameColors.cyan,
                            ),
                          ),
                        ),
                      ],
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
}

