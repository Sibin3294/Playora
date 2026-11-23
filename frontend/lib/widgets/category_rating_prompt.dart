import 'package:flutter/material.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/ratings/category_ratings.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/neon_button.dart';

/// Ask for a 1–5 star rating after a successful game (once per category / session).
Future<void> maybePromptCategoryRating(
  BuildContext context,
  String categoryId,
) async {
  final store = CategoryRatings.instance;
  await store.ensureLoaded();
  if (!store.shouldPrompt(categoryId)) return;
  store.markPrompted(categoryId);
  if (!context.mounted) return;
  await showCategoryRatingDialog(context, categoryId);
}

Future<void> showCategoryRatingDialog(
  BuildContext context,
  String categoryId,
) async {
  final category = GameCatalog.categoryById(categoryId);
  final accent = category?.accent ?? GameColors.gold;
  final title = category?.title ?? 'THIS WORLD';
  var selected = 0;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'rate',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondary) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                    decoration: panelDecoration(glow: accent),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'RATE THIS WORLD',
                          style: hudLabelStyle(color: accent, size: 12),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GameColors.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'How was that session? Tap 1–5 stars.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GameColors.mute,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 1; i <= 5; i++)
                              IconButton(
                                onPressed: () => setLocal(() => selected = i),
                                iconSize: 36,
                                icon: Icon(
                                  i <= selected
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: i <= selected
                                      ? GameColors.gold
                                      : GameColors.mute,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        NeonButton(
                          label: selected == 0 ? 'PICK STARS' : 'SUBMIT $selected★',
                          color: GameColors.gold,
                          height: 48,
                          onPressed: selected == 0
                              ? null
                              : () async {
                                  await CategoryRatings.instance
                                      .addRating(categoryId, selected);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'SKIP',
                            style: hudLabelStyle(
                              color: GameColors.mute,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

class CategoryStarsRow extends StatelessWidget {
  const CategoryStarsRow({
    super.key,
    required this.summary,
    required this.accent,
  });

  final CategoryRatingSummary summary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final avg = summary.hasRatings ? summary.average : 0.0;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              _iconFor(i, avg),
              size: 14,
              color: summary.hasRatings ? GameColors.gold : GameColors.mute,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          summary.hasRatings
              ? '${avg.toStringAsFixed(1)} (${summary.count})'
              : 'No ratings yet',
          style: TextStyle(
            color: summary.hasRatings ? accent : GameColors.mute,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  IconData _iconFor(int index, double average) {
    if (average >= index) return Icons.star_rounded;
    if (average >= index - 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }
}
