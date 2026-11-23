import 'package:flutter/material.dart';
import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/cricket/match_history.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/category_rating_prompt.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketResultScreen extends StatefulWidget {
  const CricketResultScreen({super.key, required this.result});

  final MatchResult result;

  static Route<void> route(MatchResult result) {
    return FadeScaleRoute(page: CricketResultScreen(result: result));
  }

  @override
  State<CricketResultScreen> createState() => _CricketResultScreenState();
}

class _CricketResultScreenState extends State<CricketResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  MatchResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _persistResult();
  }

  Future<void> _leave() async {
    if (result.userWonOnScore && mounted) {
      await maybePromptCategoryRating(context, 'sports');
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _persistResult() async {
    final user = result.userInnings;
    final cpu = result.cpuInnings;
    await MatchHistoryStore.add(
      MatchHistoryEntry(
        summary: result.matchSummary,
        venueName: result.venue.headline,
        scoreline:
            '${result.userTeamName} ${user.runs}/${user.wickets} – ${result.cpuTeamName} ${cpu.runs}/${cpu.wickets}',
        userWon: result.userWonOnScore,
        tied: result.tieOnScore,
        playedAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = result.userInnings;
    final cpu = result.cpuInnings;
    final won = result.userWonOnScore;
    final tied = result.tieOnScore;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${result.format.label} SCORECARD',
                  style: hudLabelStyle(color: GameColors.lime, size: 12),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final scale = 1 + (_pulse.value * 0.04);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: panelDecoration(
                                glow: won
                                    ? GameColors.gold
                                    : (tied
                                        ? GameColors.cyan
                                        : GameColors.magenta),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    won
                                        ? 'CHAMPIONS OF THE NIGHT'
                                        : (tied
                                            ? 'SCORES LEVEL'
                                            : 'HARD FOUGHT DEFEAT'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: won
                                          ? GameColors.gold
                                          : (tied
                                              ? GameColors.cyan
                                              : GameColors.coral),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    won
                                        ? 'WHAT A KNOCKOUT!'
                                        : (tied
                                            ? 'A CLASSIC TIE'
                                            : 'KEEP YOUR HEAD UP'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: GameColors.text,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    won
                                        ? 'Your XI held their nerve and sealed the win. Raise the bat.'
                                        : (tied
                                            ? 'Neither side blinked. Honours shared at stumps.'
                                            : 'The rivalry XI got home today. Reset, rebuild, and come back stronger next fixture.'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: GameColors.mute,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    result.matchSummary,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: GameColors.text,
                                      fontWeight: FontWeight.w800,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        result.venue.headline,
                        style: const TextStyle(
                          color: GameColors.lime,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.tossSummary,
                        style: const TextStyle(
                          color: GameColors.mute,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _PointsTile(
                              title: 'YOUR XI',
                              points: result.userPoints,
                              score:
                                  '${user.runs}/${user.wickets} (${user.oversLabel} ov)',
                              accent: GameColors.lime,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PointsTile(
                              title: 'RIVAL XI',
                              points: result.cpuPoints,
                              score:
                                  '${cpu.runs}/${cpu.wickets} (${cpu.oversLabel} ov)',
                              accent: GameColors.magenta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fantasy points from the middle and the death overs.',
                        style: hudLabelStyle(size: 9),
                      ),
                      const SizedBox(height: 16),
                      _InningsPanel(
                        card: result.firstInnings,
                        title: '1ST INNINGS',
                      ),
                      const SizedBox(height: 12),
                      _InningsPanel(
                        card: result.secondInnings,
                        title: '2ND INNINGS',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'BACK TO THE PAVILION',
                  color: GameColors.lime,
                  onPressed: _leave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PointsTile extends StatelessWidget {
  const _PointsTile({
    required this.title,
    required this.points,
    required this.score,
    required this.accent,
  });

  final String title;
  final int points;
  final String score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(glow: accent),
      child: Column(
        children: [
          Text(title, style: hudLabelStyle(color: accent, size: 9)),
          const SizedBox(height: 8),
          Text(
            '$points',
            style: const TextStyle(
              color: GameColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: const TextStyle(color: GameColors.mute, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'FANTASY PTS',
            style: hudLabelStyle(size: 8),
          ),
        ],
      ),
    );
  }
}

class _InningsPanel extends StatelessWidget {
  const _InningsPanel({required this.card, required this.title});

  final InningsCard card;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title • ${card.teamName}',
            style: hudLabelStyle(color: GameColors.cyan, size: 10),
          ),
          const SizedBox(height: 6),
          Text(
            '${card.runs}/${card.wickets} in ${card.oversLabel} overs  •  Fantasy ${card.totalFantasy}',
            style: const TextStyle(
              color: GameColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text('BATTING CARD', style: hudLabelStyle(size: 9)),
          const SizedBox(height: 8),
          ...card.batters.where((b) => b.balls > 0 || b.out).map((batter) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      batter.player.name,
                      style: const TextStyle(
                        color: GameColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${batter.runs} (${batter.balls})'
                    '${batter.out ? '' : batter.balls > 0 ? '*' : ''}'
                    '${batter.dismissal.isNotEmpty ? '  ${batter.dismissal}' : ''}',
                    style: const TextStyle(color: GameColors.mute, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${batter.fantasyPoints}',
                    style: hudLabelStyle(color: GameColors.gold, size: 9),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Text('BOWLING FIGURES', style: hudLabelStyle(size: 9)),
          const SizedBox(height: 8),
          ...card.bowlers.where((b) => b.balls > 0).map((bowler) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bowler.player.name,
                      style: const TextStyle(
                        color: GameColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${bowler.overs.toStringAsFixed(1)}-${bowler.maidens}-${bowler.runsConceded}-${bowler.wickets}',
                    style: const TextStyle(color: GameColors.mute, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '+${bowler.fantasyPoints}',
                    style: hudLabelStyle(color: GameColors.gold, size: 9),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
