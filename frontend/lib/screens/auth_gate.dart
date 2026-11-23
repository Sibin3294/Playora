import 'package:flutter/material.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/screens/hub_screen.dart';
import 'package:guess_game/screens/login_screen.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/streak/play_streak.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _autoGuestStarted = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      GameSession.instance.bootstrap(),
      PlayStreakStore.instance.load(),
      FirstRunStore.instance.load(),
    ]);
    if (!mounted || GameSession.forceLocal) return;
    final session = GameSession.instance;
    // Offline-friendly: enter hub as guest when there is no saved session
    // so Sports / Puzzles / Cards work without the API.
    if (!session.ready && !_autoGuestStarted) {
      _autoGuestStarted = true;
      await GameSession.instance.continueAsGuest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameSession.instance,
      builder: (context, _) {
        final session = GameSession.instance;
        if (GameSession.forceLocal) {
          return const HubScreen();
        }
        if (!session.bootstrapped || (!session.ready && _autoGuestStarted)) {
          return GameBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: GameColors.cyan),
                    const SizedBox(height: 16),
                    Text(
                      'OPENING PLAYORA',
                      style: hudLabelStyle(color: GameColors.mute),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (session.ready) {
          return const HubScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
