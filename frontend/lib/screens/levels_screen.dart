import 'package:flutter/material.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/game/player_progress.dart';
import 'package:guess_game/screens/play_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key, this.progress});

  final PlayerProgress? progress;

  static Route<void> route({PlayerProgress? progress}) {
    return FadeScaleRoute(page: LevelsScreen(progress: progress));
  }

  PlayerProgress get _progress => progress ?? PlayerProgress.instance;

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
            child: ListenableBuilder(
              listenable: _progress,
              builder: (context, _) {
                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: GameColors.mute,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'SELECT LEVEL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GameColors.text,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.4,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: panelDecoration(glow: GameColors.gold),
                      child: Column(
                        children: [
                          Text('TOTAL POINTS', style: hudLabelStyle(size: 10)),
                          const SizedBox(height: 4),
                          Text(
                            '${_progress.totalPoints}',
                            style: const TextStyle(
                              color: GameColors.gold,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (_progress.nextLocked != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: _progress.nextLevelProgress,
                                backgroundColor: const Color(0xFF222A4D),
                                color: GameColors.gold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_progress.pointsToNext} PTS TO ${_progress.nextLocked!.name}',
                              style: hudLabelStyle(
                                color: GameColors.gold,
                                size: 10,
                              ),
                            ),
                          ] else
                            Text(
                              'EVERY LEVEL UNLOCKED',
                              style: hudLabelStyle(color: GameColors.lime),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        itemCount: HuntLevel.all.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final level = HuntLevel.all[index];
                          return _LevelCard(
                            level: level,
                            unlocked: _progress.isUnlocked(level),
                            selected: _progress.selectedLevelId == level.id,
                            points: _progress.totalPoints,
                            onSelect: () =>
                                GameSession.instance.selectLevel(level),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeonButton(
                      label: 'HUNT ${_progress.selectedLevel.name}',
                      color: _progress.selectedLevel.accent,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          PlayScreen.route(level: _progress.selectedLevel),
                        );
                      },
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.selected,
    required this.points,
    required this.onSelect,
  });

  final HuntLevel level;
  final bool unlocked;
  final bool selected;
  final int points;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? level.accent : GameColors.mute;
    return GestureDetector(
      onTap: unlocked ? onSelect : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: panelDecoration(
          border: selected ? accent : GameColors.panelBorder,
          glow: selected ? accent : GameColors.violet,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
                color: accent.withOpacity(0.12),
              ),
              child: Text(
                '${level.id}',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        level.name,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Text(
                          'SELECTED',
                          style: hudLabelStyle(color: accent, size: 9),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked
                        ? '${level.rangeLabel}  •  ${level.maxAttempts} shots  •  x${level.multiplier}'
                        : 'Need ${level.pointsToUnlock - points} more pts',
                    style: const TextStyle(
                      color: GameColors.mute,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    level.blurb,
                    style:
                        const TextStyle(color: GameColors.mute, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              unlocked
                  ? (selected ? Icons.check_circle : Icons.lock_open_rounded)
                  : Icons.lock_rounded,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}
