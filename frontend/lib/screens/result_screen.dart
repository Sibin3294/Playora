import 'package:flutter/material.dart';
import 'package:guess_game/api/game_session.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/game/player_progress.dart';
import 'package:guess_game/screens/campaign_clear_screen.dart';
import 'package:guess_game/screens/history_screen.dart';
import 'package:guess_game/screens/play_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/category_rating_prompt.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.engine,
    this.archive,
    this.progress,
    this.settledOnServer = false,
    this.awardedPoints,
    this.awardedBonus,
    this.unlockedLevels = const [],
  });

  final GuessEngine engine;
  final HuntArchive? archive;
  final PlayerProgress? progress;
  final bool settledOnServer;
  final int? awardedPoints;
  final int? awardedBonus;
  final List<HuntLevel> unlockedLevels;

  static Route<void> route({
    required GuessEngine engine,
    bool settledOnServer = false,
    int? awardedPoints,
    int? awardedBonus,
    List<HuntLevel> unlockedLevels = const [],
  }) {
    return FadeScaleRoute(
      page: ResultScreen(
        engine: engine,
        settledOnServer: settledOnServer,
        awardedPoints: awardedPoints,
        awardedBonus: awardedBonus,
        unlockedLevels: unlockedLevels,
      ),
    );
  }

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final int _points;
  late final int _bonus;
  late final List<HuntLevel> _unlocked;

  HuntArchive get _archive => widget.archive ?? HuntArchive.instance;
  PlayerProgress get _progress => widget.progress ?? PlayerProgress.instance;
  HuntLevel get _level => widget.engine.level ?? _progress.selectedLevel;

  @override
  void initState() {
    super.initState();
    if (widget.settledOnServer) {
      _points = widget.awardedPoints ?? widget.engine.pointsEarned;
      _bonus = widget.awardedBonus ?? 0;
      _unlocked = widget.unlockedLevels;
    } else {
      _points = widget.engine.pointsEarned;
      _unlocked = _progress.award(_points);
      var bonus = 0;
      if (widget.engine.isWon &&
          _level.isLast &&
          _progress.markCampaignCleared()) {
        bonus = PlayerProgress.campaignBonus;
        _progress.award(bonus);
      }
      _bonus = bonus;
    }
    _archive.addFromEngine(widget.engine, points: _points + _bonus);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  Future<void> _afterWinLeave(VoidCallback next) async {
    if (widget.engine.isWon && mounted) {
      await maybePromptCategoryRating(context, 'number');
    }
    if (!mounted) return;
    next();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _loseCopy {
    final distance = widget.engine.closestDistance;
    if (distance <= 2) {
      return 'You were only $distance away. That hunt was yours. Go claim the next one.';
    }
    if (distance <= 6) {
      return 'So close it almost counted. Trust the heat meter and run it back.';
    }
    return 'Every hunter misses. The number is still out there, and you are getting sharper.';
  }

  @override
  Widget build(BuildContext context) {
    final won = widget.engine.isWon;
    if (won && _level.isLast) {
      return CampaignClearScreen(
        engine: widget.engine,
        level: _level,
        points: _points,
        totalPoints: _progress.totalPoints,
        bonus: _bonus,
        archive: _archive,
      );
    }
    final accent = won ? GameColors.gold : GameColors.violet;
    final title = won ? 'JACKPOT' : 'SO CLOSE';
    final subtitle = won
        ? 'You cracked the secret number.'
        : 'The hunt ended, but you are not done.';

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Text(
                  won ? 'MISSION COMPLETE' : 'MISSION FAILED',
                  style: hudLabelStyle(
                    color: won ? GameColors.lime : GameColors.coral,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, child) {
                            final glow = 18 + (_pulse.value * 22);
                            return Container(
                              width: 168,
                              height: 168,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    accent.withOpacity(0.9),
                                    const Color(0xFF140B2E),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.45),
                                    blurRadius: glow,
                                    spreadRadius: 6,
                                  ),
                                ],
                                border: Border.all(color: accent, width: 3),
                              ),
                              child: child,
                            );
                          },
                          child: Text(
                            won ? '★' : '✦',
                            style: TextStyle(color: accent, fontSize: 64),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          title,
                          style: TextStyle(
                            color: accent,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GameColors.mute,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration:
                              panelDecoration(border: accent, glow: accent),
                          child: Column(
                            children: [
                              Text(
                                won ? 'THE NUMBER WAS' : 'HIDDEN NUMBER',
                                style: hudLabelStyle(color: accent),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.engine.secretNumber}',
                                style: const TextStyle(
                                  color: GameColors.text,
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                              Text(
                                won
                                    ? 'Solved in ${widget.engine.attemptsUsed} of ${widget.engine.maxAttempts} shots'
                                    : 'Closest shot was ${widget.engine.closestDistance} away',
                                style: const TextStyle(
                                  color: GameColors.mute,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _points > 0 ? '+$_points PTS' : 'NO POINTS',
                                style: TextStyle(
                                  color: _points > 0
                                      ? GameColors.gold
                                      : GameColors.mute,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                '${_level.name}  •  ${_progress.totalPoints} total',
                                style: const TextStyle(
                                  color: GameColors.mute,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_unlocked.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            '${_unlocked.map((level) => level.name).join(' + ')} UNLOCKED',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GameColors.lime,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                        if (!won) ...[
                          const SizedBox(height: 16),
                          Text(
                            _loseCopy,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GameColors.text,
                              height: 1.45,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        if (won) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Sharp instincts. Run another hunt and protect the streak.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GameColors.text,
                              height: 1.45,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_level.next != null &&
                    _progress.isUnlocked(_level.next!)) ...[
                  NeonButton(
                    label: 'NEXT LEVEL',
                    color: GameColors.lime,
                    onPressed: () => _afterWinLeave(() {
                      final next = _level.next!;
                      GameSession.instance.selectLevel(next);
                      Navigator.of(context).pushReplacement(
                        PlayScreen.route(level: next),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                NeonButton(
                  label: 'PLAY AGAIN',
                  color: won ? GameColors.gold : GameColors.cyan,
                  onPressed: () => _afterWinLeave(() {
                    Navigator.of(context).pushReplacement(
                      PlayScreen.route(level: _level),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _afterWinLeave(() {
                    Navigator.of(context).push(HistoryScreen.route(
                      archive: _archive,
                    ));
                  }),
                  child: Text(
                    'VIEW HUNT LOG',
                    style: hudLabelStyle(color: GameColors.cyan),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _afterWinLeave(() => Navigator.of(context).pop()),
                  child: Text(
                    'BACK TO BASE',
                    style: hudLabelStyle(color: GameColors.mute),
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
