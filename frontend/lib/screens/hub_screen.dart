import 'package:flutter/material.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/branding/app_brand.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/intro/first_run_store.dart';
import 'package:guess_game/ratings/category_ratings.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/screens/category_games_screen.dart';
import 'package:guess_game/screens/history_screen.dart';
import 'package:guess_game/screens/profile_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/category_rating_prompt.dart';
import 'package:guess_game/widgets/feature_tip.dart';
import 'package:guess_game/widgets/first_run_intro.dart';
import 'package:guess_game/widgets/game_background.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  @override
  void initState() {
    super.initState();
    CategoryRatings.instance.ensureLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeShowFirstRunIntro(
        context,
        id: FirstRunStore.hubWelcomeId,
        pages: const [
          FirstRunPage(
            title: 'WELCOME TO PLAYORA',
            body:
                'This is your game hub. Pick a world to play — Numbers, Sports, and more over time.',
            accent: GameColors.cyan,
            icon: Icons.sports_esports_rounded,
          ),
          FirstRunPage(
            title: 'NUMBER HUNTER',
            body:
                'Guess the secret number, climb levels, and earn points. Sign in when online to sync progress.',
            accent: GameColors.magenta,
            icon: Icons.pin_rounded,
          ),
          FirstRunPage(
            title: 'SPORTS & PUZZLES',
            body:
                'Draft cricket XIs, private rooms, leagues — or peel Face Reveal tiles and name the star in 5 chances.',
            accent: GameColors.lime,
            icon: Icons.sports_cricket_rounded,
          ),
          FirstRunPage(
            title: 'STREAKS & PROFILE',
            body:
                'Play on consecutive days to build a streak and unlock Bronze, Silver, or Gold tags on your profile.',
            accent: GameColors.gold,
            icon: Icons.local_fire_department_rounded,
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
              listenable: GameSession.instance,
              builder: (context, _) {
                final session = GameSession.instance;
                final greeting = session.isLoggedIn
                    ? (session.name?.toUpperCase() ?? 'PLAYER')
                    : 'GUEST';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppBrand.hubEyebrow,
                          style: hudLabelStyle(color: GameColors.cyan, size: 12),
                        ),
                        const Spacer(),
                        ListenableBuilder(
                          listenable: HuntArchive.instance,
                          builder: (context, _) {
                            final count = HuntArchive.instance.huntCount;
                            return IconButton(
                              tooltip: 'Campaign history',
                              onPressed: () {
                                Navigator.of(context)
                                    .push(HistoryScreen.route());
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
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Profile',
                          onPressed: () {
                            Navigator.of(context).push(ProfileScreen.route());
                          },
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            color: GameColors.mute,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'CHOOSE YOUR\nWORLD',
                      style: TextStyle(
                        color: GameColors.text,
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome, $greeting. Pick a category — more worlds can join later.',
                      style: const TextStyle(
                        color: GameColors.mute,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: CategoryRatings.instance,
                        builder: (context, _) {
                          return ListView.separated(
                            itemCount: GameCatalog.categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final category = GameCatalog.categories[index];
                              final tile = _CategoryTile(
                                category: category,
                                rating: CategoryRatings.instance
                                    .summaryFor(category.id),
                                onTap: () {
                                  Navigator.of(context).push(
                                    CategoryGamesScreen.route(category),
                                  );
                                },
                              );
                              if (category.id == 'puzzles') {
                                return FeatureTip(
                                  id: FirstRunStore.tipPuzzlesId,
                                  title: 'New · Puzzles',
                                  message:
                                      'Face Reveal — peel numbered tiles and name the sports star in 5 chances.',
                                  accent: GameColors.violet,
                                  child: tile,
                                );
                              }
                              if (category.id == 'cards') {
                                return FeatureTip(
                                  id: FirstRunStore.tipCardGamesId,
                                  title: 'New · Card Games',
                                  message:
                                      'Stat Battle — cricket Top Trumps. Pick a stat and play until one deck is empty.',
                                  accent: GameColors.magenta,
                                  child: tile,
                                );
                              }
                              return tile;
                            },
                          );
                        },
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.rating,
    required this.onTap,
  });

  final GameCategory category;
  final CategoryRatingSummary rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final playable = category.playableCount;
    final status = playable > 0
        ? '$playable LIVE'
        : 'COMING SOON';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: panelDecoration(glow: category.accent),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.accent.withOpacity(0.12),
                  border: Border.all(color: category.accent.withOpacity(0.55)),
                ),
                child: Icon(category.icon, color: category.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: GameColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CategoryStarsRow(
                      summary: rating,
                      accent: category.accent,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        color: GameColors.mute,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: hudLabelStyle(color: category.accent, size: 9),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: category.accent.withOpacity(0.9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
