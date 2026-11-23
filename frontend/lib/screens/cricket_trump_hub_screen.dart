import 'package:flutter/material.dart';
import 'package:guess_game/cards/trump_models.dart';
import 'package:guess_game/cards/trump_progression.dart';
import 'package:guess_game/screens/cricket_trump_screen.dart';
import 'package:guess_game/screens/cricket_trump_stat_pick_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketTrumpHubScreen extends StatefulWidget {
  const CricketTrumpHubScreen({super.key});

  static Route<void> route() =>
      FadeScaleRoute(page: const CricketTrumpHubScreen());

  @override
  State<CricketTrumpHubScreen> createState() => _CricketTrumpHubScreenState();
}

class _CricketTrumpHubScreenState extends State<CricketTrumpHubScreen> {
  final _progress = TrumpProgression.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _progress.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _openLevel(int level) async {
    if (!_progress.isUnlocked(level)) return;

    if (_progress.needsStatPick(level)) {
      final picks = await Navigator.of(context).push<List<TrumpStat>>(
        CricketTrumpStatPickScreen.route(
          level: level,
          pickCount: TrumpLevels.picksNeededForLevel(level),
          available: _progress.availableToPick(),
        ),
      );
      if (!mounted) return;
      if (picks == null || picks.isEmpty) return;
      await _progress.appendPicks(picks);
      if (!mounted) return;
      setState(() {});
    }

    final stats = _progress.statsForLevel(level);
    if (stats.length < TrumpLevels.statsForLevel(level)) {
      return;
    }

    await Navigator.of(context).push(
      CricketTrumpScreen.route(
        level: level,
        activeStats: stats,
        deckSize: TrumpLevels.deckSizeForLevel(level),
      ),
    );
    if (!mounted) return;
    await _progress.ensureLoaded();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Text(
                      'STAT BATTLE',
                      style: hudLabelStyle(color: GameColors.magenta, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Level Progression',
                  style: TextStyle(
                    color: GameColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Win a level to unlock the next. Each advance adds more stats and a bigger deck (max ${TrumpLevels.maxStats} stats / ${TrumpLevels.maxCards} cards).',
                  style: const TextStyle(
                    color: GameColors.mute,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: GameColors.magenta,
                          ),
                        )
                      : ListView.separated(
                          itemCount: TrumpLevels.maxLevel,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final level = index + 1;
                            final unlocked = _progress.isUnlocked(level);
                            final cleared = _progress.isCleared(level);
                            final stats = TrumpLevels.statsForLevel(level);
                            final cards = TrumpLevels.deckSizeForLevel(level);
                            final needsPick =
                                unlocked && _progress.needsStatPick(level);

                            final best = _progress.bestWinTime(level);
                            final last = _progress.lastWinTime(level);
                            return _LevelTile(
                              level: level,
                              unlocked: unlocked,
                              cleared: cleared,
                              stats: stats,
                              cards: cards,
                              needsPick: needsPick,
                              isFinal: TrumpLevels.isFinalLevel(level),
                              bestTime: best,
                              lastTime: last,
                              onPlay: () => _openLevel(level),
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

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.cleared,
    required this.stats,
    required this.cards,
    required this.needsPick,
    required this.isFinal,
    required this.bestTime,
    required this.lastTime,
    required this.onPlay,
  });

  final int level;
  final bool unlocked;
  final bool cleared;
  final int stats;
  final int cards;
  final bool needsPick;
  final bool isFinal;
  final Duration? bestTime;
  final Duration? lastTime;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final accent = !unlocked
        ? GameColors.mute
        : (cleared ? GameColors.lime : GameColors.magenta);

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: panelDecoration(glow: accent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'LEVEL $level',
                  style: hudLabelStyle(color: accent, size: 12),
                ),
                const Spacer(),
                if (!unlocked)
                  const Icon(Icons.lock_rounded, color: GameColors.mute, size: 18)
                else if (cleared)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: GameColors.lime,
                    size: 18,
                  )
                else if (needsPick)
                  Text(
                    'PICK STATS',
                    style: hudLabelStyle(color: GameColors.gold, size: 9),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isFinal ? 'Final challenge' : 'Battle the CPU',
              style: const TextStyle(
                color: GameColors.text,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$stats stats  ·  $cards cards in deck'
              '${level == 1 ? '  ·  starter pack' : ''}'
              '${level > 1 ? '  ·  +${TrumpLevels.picksNeededForLevel(level)} new stats' : ''}',
              style: const TextStyle(color: GameColors.mute, fontSize: 13),
            ),
            if (bestTime != null || lastTime != null) ...[
              const SizedBox(height: 8),
              Text(
                bestTime != null
                    ? 'Best win ${TrumpProgression.formatDuration(bestTime!)}'
                        '${lastTime != null && lastTime != bestTime ? '  ·  last ${TrumpProgression.formatDuration(lastTime!)}' : ''}'
                    : 'Last win ${TrumpProgression.formatDuration(lastTime!)}',
                style: const TextStyle(
                  color: GameColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
            if (unlocked) ...[
              const SizedBox(height: 14),
              NeonButton(
                label: needsPick ? 'CHOOSE STATS & PLAY' : 'PLAY LEVEL $level',
                color: accent,
                height: 46,
                onPressed: onPlay,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
