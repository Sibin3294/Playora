import 'package:flutter/material.dart';
import 'package:guess_game/streak/play_streak.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class StreakDayScreen extends StatelessWidget {
  const StreakDayScreen({super.key, required this.result});

  final PlayStreakResult result;

  static Route<void> route(PlayStreakResult result) {
    return FadeScaleRoute(page: StreakDayScreen(result: result));
  }

  Color get _accent {
    switch (result.earnedTag) {
      case StreakTag.gold:
        return GameColors.gold;
      case StreakTag.silver:
        return const Color(0xFFC0C7D6);
      case StreakTag.bronze:
        return const Color(0xFFCD7F32);
      case StreakTag.none:
        return GameColors.cyan;
    }
  }

  String get _headline {
    if (result.currentStreak <= 1) return 'STREAK STARTED';
    if (result.tagJustUnlocked != null) {
      return '${result.tagJustUnlocked!.label} UNLOCKED';
    }
    return 'DAY ${result.currentStreak} STREAK';
  }

  String get _body {
    if (result.tagJustUnlocked == StreakTag.bronze) {
      return 'Seven days on the board. You earned the Bronze User tag.';
    }
    if (result.tagJustUnlocked == StreakTag.silver) {
      return 'Fifteen days strong. Silver User is now on your profile.';
    }
    if (result.tagJustUnlocked == StreakTag.gold) {
      return 'A full month of play. Gold User shines on your profile.';
    }
    if (result.currentStreak <= 1) {
      return 'Come back tomorrow to keep the fire alive across any game world.';
    }
    return 'You played again today. Keep showing up — Bronze at 7, Silver at 15, Gold at 30.';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'DAILY STREAK',
                  style: hudLabelStyle(color: accent, size: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: panelDecoration(glow: accent),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: accent,
                        size: 64,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _headline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${result.currentStreak}',
                        style: TextStyle(
                          color: GameColors.text,
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: [
                            Shadow(color: accent.withOpacity(0.45), blurRadius: 24),
                          ],
                        ),
                      ),
                      Text(
                        result.currentStreak == 1 ? 'DAY' : 'DAYS',
                        style: hudLabelStyle(color: GameColors.mute, size: 12),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameColors.mute,
                          height: 1.4,
                          fontSize: 15,
                        ),
                      ),
                      if (result.earnedTag != StreakTag.none) ...[
                        const SizedBox(height: 18),
                        _TagChip(tag: result.earnedTag),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Best streak: ${result.longestStreak} day${result.longestStreak == 1 ? '' : 's'}',
                        style: hudLabelStyle(size: 10),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                NeonButton(
                  label: 'CONTINUE',
                  color: accent,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final StreakTag tag;

  @override
  Widget build(BuildContext context) {
    final color = switch (tag) {
      StreakTag.gold => GameColors.gold,
      StreakTag.silver => const Color(0xFFC0C7D6),
      StreakTag.bronze => const Color(0xFFCD7F32),
      StreakTag.none => GameColors.mute,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
        color: color.withOpacity(0.14),
      ),
      child: Text(
        '${tag.label} USER',
        style: hudLabelStyle(color: color, size: 10),
      ),
    );
  }
}

/// Records a play day and pushes the streak UI when it is a new calendar day.
Future<void> recordPlayAndMaybeShowStreak(BuildContext context) async {
  final result = await PlayStreakStore.instance.recordPlay();
  if (!result.isNewPlayDay || !context.mounted) return;
  await Navigator.of(context).push(StreakDayScreen.route(result));
}
