import 'package:flutter/material.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/screens/cricket_format_screen.dart';
import 'package:guess_game/screens/cricket_trump_hub_screen.dart';
import 'package:guess_game/screens/home_screen.dart';
import 'package:guess_game/screens/sports_face_puzzle_screen.dart';
import 'package:guess_game/screens/streak_day_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CategoryGamesScreen extends StatelessWidget {
  const CategoryGamesScreen({super.key, required this.category});

  final GameCategory category;

  static Route<void> route(GameCategory category) {
    return FadeScaleRoute(page: CategoryGamesScreen(category: category));
  }

  Future<void> _openGame(BuildContext context, CatalogGame game) async {
    if (!game.isPlayable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GameColors.panelSolid,
          content: Text(
            '${game.title} is coming soon.',
            style: const TextStyle(color: GameColors.text),
          ),
        ),
      );
      return;
    }

    await recordPlayAndMaybeShowStreak(context);
    if (!context.mounted) return;

    switch (game.id) {
      case GameCatalog.numberHunterId:
        Navigator.of(context).push(FadeScaleRoute(page: const HomeScreen()));
      case GameCatalog.cricketId:
        Navigator.of(context).push(CricketFormatScreen.route());
      case GameCatalog.sportsFacePuzzleId:
        Navigator.of(context).push(SportsFacePuzzleScreen.route());
      case GameCatalog.cricketTrumpId:
        Navigator.of(context).push(CricketTrumpHubScreen.route());
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: GameColors.panelSolid,
            content: Text(
              'That room is not wired yet.',
              style: TextStyle(color: GameColors.text),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to arcade',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Text(
                      category.title,
                      style: hudLabelStyle(color: category.accent, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category.subtitle,
                  style: const TextStyle(
                    color: GameColors.mute,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: category.games.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final game = category.games[index];
                      return _GameTile(
                        game: game,
                        accent: category.accent,
                        onPlay: () => _openGame(context, game),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.accent,
    required this.onPlay,
  });

  final CatalogGame game;
  final Color accent;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final live = game.isPlayable;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: panelDecoration(
        glow: live ? accent : GameColors.panelBorder,
        border: live ? null : GameColors.panelBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  game.title,
                  style: const TextStyle(
                    color: GameColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text(
                live ? 'LIVE' : 'SOON',
                style: hudLabelStyle(
                  color: live ? GameColors.lime : GameColors.gold,
                  size: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            game.tagline,
            style: const TextStyle(
              color: GameColors.mute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: live ? 'ENTER' : 'COMING SOON',
            color: live ? accent : GameColors.mute,
            height: 48,
            onPressed: live ? onPlay : null,
          ),
        ],
      ),
    );
  }
}
