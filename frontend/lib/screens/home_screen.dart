import 'package:flutter/material.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/game/player_progress.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/screens/history_screen.dart';
import 'package:guess_game/screens/hub_screen.dart';
import 'package:guess_game/screens/levels_screen.dart';
import 'package:guess_game/screens/login_screen.dart';
import 'package:guess_game/screens/play_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/first_run_intro.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowFirstRunIntro(
        context,
        id: FirstRunStore.numberHunterId,
        pages: const [
          FirstRunPage(
            title: 'NUMBER HUNTER',
            body:
                'Pick a level and hunt the secret number. Warmer clues mean you are closer. Finish hunts to unlock harder ranges.',
            accent: GameColors.cyan,
            icon: Icons.travel_explore_rounded,
          ),
          FirstRunPage(
            title: 'POINTS & HISTORY',
            body:
                'Wins earn points. Check History for past hunts. When the API is online, progress can sync with your account.',
            accent: GameColors.gold,
            icon: Icons.emoji_events_rounded,
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ListenableBuilder(
              listenable: Listenable.merge([
                HuntArchive.instance,
                PlayerProgress.instance,
                GameSession.instance,
              ]),
              builder: (context, _) {
                final progress = PlayerProgress.instance;
                final level = progress.selectedLevel;
                final count = HuntArchive.instance.huntCount;
                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to arcade',
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                              return;
                            }
                            Navigator.of(context).pushReplacement(
                              FadeScaleRoute(page: const HubScreen()),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: GameColors.mute,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: GameColors.magenta),
                            color: GameColors.magenta.withOpacity(0.12),
                          ),
                          child: Text(
                            'NUMBER GAMES',
                            style: hudLabelStyle(
                                color: GameColors.magenta, size: 10),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Hunt log',
                          onPressed: () {
                            Navigator.of(context).push(HistoryScreen.route());
                          },
                          icon: Badge(
                            isLabelVisible: count > 0,
                            label: Text('$count'),
                            backgroundColor: GameColors.gold,
                            textColor: const Color(0xFF071018),
                            child: const Icon(
                              Icons.history_rounded,
                              color: GameColors.cyan,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: GameSession.instance.isLoggedIn
                              ? 'Log out'
                              : 'Account',
                          onPressed: () async {
                            final session = GameSession.instance;
                            if (session.isLoggedIn || session.ready) {
                              await session.logout();
                            }
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              FadeScaleRoute(page: const LoginScreen()),
                              (_) => false,
                            );
                          },
                          icon: Icon(
                            GameSession.instance.isLoggedIn
                                ? Icons.logout_rounded
                                : Icons.person_outline_rounded,
                            color: GameColors.mute,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            const _Orb(),
                            const SizedBox(height: 24),
                            const Text(
                              'NUMBER',
                              style: TextStyle(
                                color: GameColors.cyan,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 10,
                              ),
                            ),
                            const Text(
                              'HUNTER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameColors.text,
                                fontSize: 52,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${level.name}  •  ${level.rangeLabel}\nFewer shots, more points. Unlock bigger hunts.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GameColors.mute,
                                fontSize: 15,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatChip(
                                    title: 'RANGE',
                                    value: level.rangeLabel,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatChip(
                                    title: 'SHOTS',
                                    value: '${level.maxAttempts}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatChip(
                                    title: 'POINTS',
                                    value: '${progress.totalPoints}',
                                    color: GameColors.gold,
                                  ),
                                ),
                              ],
                            ),
                            if (progress.nextLocked != null) ...[
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: progress.nextLevelProgress,
                                  backgroundColor: const Color(0xFF222A4D),
                                  color: GameColors.gold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${progress.pointsToNext} PTS TO ${progress.nextLocked!.name}',
                                style: hudLabelStyle(
                                    color: GameColors.gold, size: 10),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    NeonButton(
                      label: 'PLAY ${level.name}',
                      color: level.accent,
                      onPressed: () {
                        Navigator.of(context).push(
                          PlayScreen.route(level: level),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      label: 'LEVELS',
                      outlined: true,
                      color: GameColors.gold,
                      height: 48,
                      onPressed: () {
                        Navigator.of(context).push(LevelsScreen.route());
                      },
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      label: 'HISTORY',
                      outlined: true,
                      color: GameColors.cyan,
                      height: 48,
                      onPressed: () {
                        Navigator.of(context).push(HistoryScreen.route());
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      GameSession.instance.ready
                          ? (GameSession.instance.offline
                              ? 'OFFLINE PLAY'
                              : (GameSession.instance.isLoggedIn
                                  ? 'SIGNED IN${GameSession.instance.name != null ? ' • ${GameSession.instance.name!.toUpperCase()}' : ''}'
                                  : 'GUEST SESSION'))
                          : 'OFFLINE',
                      textAlign: TextAlign.center,
                      style: hudLabelStyle(
                        size: 10,
                        color: GameSession.instance.ready
                            ? (GameSession.instance.offline
                                ? GameColors.gold
                                : GameColors.lime)
                            : GameColors.mute,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF5B2C9D), Color(0xFF140B2E)],
        ),
        border: Border.all(color: GameColors.cyan, width: 2),
        boxShadow: [
          BoxShadow(
            color: GameColors.cyan.withOpacity(0.35),
            blurRadius: 36,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: GameColors.magenta.withOpacity(0.25),
            blurRadius: 48,
          ),
        ],
      ),
      child: const Text(
        '?',
        style: TextStyle(
          color: GameColors.text,
          fontSize: 64,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.title,
    required this.value,
    this.color = GameColors.text,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: panelDecoration(),
      child: Column(
        children: [
          Text(title, style: hudLabelStyle(size: 9)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
