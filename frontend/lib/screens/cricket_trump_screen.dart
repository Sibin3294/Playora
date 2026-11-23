import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/cards/trump_engine.dart';
import 'package:guess_game/cards/trump_models.dart';
import 'package:guess_game/cards/trump_progression.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/history/play_history.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/category_rating_prompt.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketTrumpScreen extends StatefulWidget {
  const CricketTrumpScreen({
    super.key,
    required this.level,
    required this.activeStats,
    required this.deckSize,
  });

  final int level;
  final List<TrumpStat> activeStats;
  final int deckSize;

  static Route<void> route({
    required int level,
    required List<TrumpStat> activeStats,
    required int deckSize,
  }) {
    return FadeScaleRoute(
      page: CricketTrumpScreen(
        level: level,
        activeStats: activeStats,
        deckSize: deckSize,
      ),
    );
  }

  @override
  State<CricketTrumpScreen> createState() => _CricketTrumpScreenState();
}

class _CricketTrumpScreenState extends State<CricketTrumpScreen>
    with TickerProviderStateMixin {
  late TrumpEngine _engine;
  TrumpRoundResult? _reveal;
  bool _resolving = false;
  bool _callerWasUser = true;
  int _cardsInPlay = 2;
  bool _matchEndShown = false;
  bool _unlockedNext = false;
  TrumpWinTimeResult? _winTime;

  late final AnimationController _confetti;
  late final List<_PaperBit> _bits;
  bool _celebrate = false;

  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _tick;
  Duration? _targetBest;
  Duration? _targetLast;

  TrumpEngine _makeEngine() => TrumpEngine(
        deckSize: widget.deckSize,
        activeStats: widget.activeStats,
      );

  @override
  void initState() {
    super.initState();
    _engine = _makeEngine();
    final random = Random(21);
    _bits = List.generate(64, (_) => _PaperBit.random(random));
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _loadTargetsAndStartTimer();
  }

  Future<void> _loadTargetsAndStartTimer() async {
    await TrumpProgression.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _targetBest = TrumpProgression.instance.bestWinTime(widget.level);
      _targetLast = TrumpProgression.instance.lastWinTime(widget.level);
    });
    _startTimer();
  }

  void _startTimer() {
    _tick?.cancel();
    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _startedAt == null || _engine.isOver) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt!);
      });
    });
  }

  void _stopTimer() {
    _tick?.cancel();
    _tick = null;
    if (_startedAt != null) {
      _elapsed = DateTime.now().difference(_startedAt!);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _newMatch() {
    _confetti.stop();
    setState(() {
      _engine = _makeEngine();
      _reveal = null;
      _resolving = false;
      _callerWasUser = true;
      _cardsInPlay = 2;
      _matchEndShown = false;
      _unlockedNext = false;
      _winTime = null;
      _celebrate = false;
      _targetBest = TrumpProgression.instance.bestWinTime(widget.level);
      _targetLast = TrumpProgression.instance.lastWinTime(widget.level);
    });
    _startTimer();
  }

  Future<void> _play(TrumpStat stat, {required bool calledByUser}) async {
    if (_engine.isOver || _resolving) return;
    final stake = _engine.pot.length + 2;
    setState(() {
      _resolving = true;
      _callerWasUser = calledByUser;
      _cardsInPlay = stake;
      _reveal = _engine.playRound(stat);
    });
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    if (_engine.isOver) {
      await _showMatchEnd();
      if (!mounted) return;
      setState(() {
        _reveal = null;
        _resolving = false;
      });
      return;
    }

    setState(() {
      _reveal = null;
      _resolving = false;
    });
    if (!_engine.userChooses) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted || _engine.isOver) return;
      final cpuCard = _engine.cpuTop;
      if (cpuCard == null) return;
      await _play(_engine.cpuPickStat(cpuCard), calledByUser: false);
    }
  }

  String _timeLine(TrumpWinTimeResult time) {
    final now = TrumpProgression.formatDuration(time.elapsed);
    if (time.previousBest == null) {
      return 'Time $now — first win recorded!';
    }
    final best = TrumpProgression.formatDuration(time.previousBest!);
    if (time.isNewBest) {
      return 'Time $now — new best! (was $best)';
    }
    if (time.beatLastWin && time.previousLast != null) {
      final last = TrumpProgression.formatDuration(time.previousLast!);
      return 'Time $now — beat last win ($last). Best stays $best.';
    }
    return 'Time $now — best remains $best. Push faster!';
  }

  Future<void> _showMatchEnd() async {
    if (_matchEndShown) return;
    _matchEndShown = true;
    _stopTimer();
    final userWon = _engine.userWon;
    TrumpWinTimeResult? winTime;
    if (userWon) {
      final result = await TrumpProgression.instance.recordWin(
        widget.level,
        elapsed: _elapsed,
      );
      _unlockedNext = result.unlockedNext;
      winTime = result.time;
      _winTime = winTime;
      setState(() => _celebrate = true);
      _confetti.repeat();
    }

    await PlayHistoryStore.instance.record(
      gameId: GameCatalog.cricketTrumpId,
      resultLabel: userWon ? 'WIN' : 'LOSS',
      headline: 'Level ${widget.level}',
      summary: userWon
          ? 'Cleared in ${TrumpProgression.formatDuration(_elapsed)} · ${widget.activeStats.length} stats'
          : 'CPU swept the deck · ${TrumpProgression.formatDuration(_elapsed)}',
      won: userWon,
      detail: '${widget.deckSize} cards',
    );

    final nextLevel = widget.level + 1;
    final body = userWon
        ? (_unlockedNext
            ? 'Level ${widget.level} cleared!\nLevel $nextLevel unlocked.'
            : (TrumpLevels.isFinalLevel(widget.level)
                ? 'Final level cleared.\nYou mastered Stat Battle!'
                : 'Level ${widget.level} cleared again.'))
        : 'CPU swept the deck.';

    final timeNote = userWon && winTime != null
        ? _timeLine(winTime)
        : 'Time ${TrumpProgression.formatDuration(_elapsed)}';

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'match-end',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondary) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.78, end: 1).animate(curved),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  decoration: panelDecoration(
                    glow: userWon ? GameColors.gold : GameColors.coral,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userWon
                            ? Icons.emoji_events_rounded
                            : Icons.sports_esports_rounded,
                        color: userWon ? GameColors.gold : GameColors.coral,
                        size: 54,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userWon ? 'CONGRATULATIONS!' : 'CPU WINS',
                        textAlign: TextAlign.center,
                        style: hudLabelStyle(
                          color: userWon ? GameColors.gold : GameColors.coral,
                          size: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        timeNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: userWon && (winTime?.isNewBest ?? false)
                              ? GameColors.lime
                              : GameColors.gold,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userWon
                            ? 'Level ${widget.level} · ${widget.activeStats.length} stats'
                            : 'Retry this level when ready.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameColors.mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      NeonButton(
                        label: userWon ? 'AWESOME' : 'OK',
                        color: userWon ? GameColors.gold : GameColors.coral,
                        height: 48,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (userWon && mounted) {
      await maybePromptCategoryRating(context, 'cards');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userCard = _reveal?.userCard ?? _engine.userTop;
    final cpuCard = _reveal?.cpuCard;
    final showCpu = _reveal != null;
    final yourTurn = _engine.userChooses && !_resolving && !_engine.isOver;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_celebrate)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        bits: _bits,
                        t: _confetti.value,
                      ),
                    );
                  },
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
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
                          'STAT BATTLE · L${widget.level}',
                          style: hudLabelStyle(
                            color: GameColors.magenta,
                            size: 12,
                          ),
                        ),
                        const Spacer(),
                        _LiveTimerChip(
                          elapsed: _elapsed,
                          running: !_engine.isOver,
                        ),
                        if (_engine.isOver)
                          TextButton(
                            onPressed: _newMatch,
                            child: Text(
                              'REMATCH',
                              style: hudLabelStyle(
                                color: GameColors.gold,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_targetBest != null || _targetLast != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _targetBest != null
                            ? 'Beat your best ${TrumpProgression.formatDuration(_targetBest!)}'
                                '${_targetLast != null && _targetLast != _targetBest ? ' · last win ${TrumpProgression.formatDuration(_targetLast!)}' : ''}'
                            : 'Last win ${TrumpProgression.formatDuration(_targetLast!)} — set a best!',
                        textAlign: TextAlign.center,
                        style: hudLabelStyle(color: GameColors.gold, size: 9),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _Scoreboard(
                      userCards: _engine.userDeck.length,
                      cpuCards: _engine.cpuDeck.length,
                      potCards: _engine.pot.length,
                    ),
                    const SizedBox(height: 10),
                    _TurnBanner(
                      isOver: _engine.isOver,
                      userWon: _engine.userWon,
                      yourTurn: yourTurn,
                      resolving: _resolving,
                      userChooses: _engine.userChooses,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                            child: _StatCardView(
                              title: 'YOU',
                              card: userCard,
                              accent: GameColors.cyan,
                              activeStats: widget.activeStats,
                              active: yourTurn ||
                                  (_resolving &&
                                      _reveal?.outcome ==
                                          TrumpRoundOutcome.userWin),
                              highlightStat: _reveal?.stat,
                              highlightWin: _reveal?.outcome ==
                                  TrumpRoundOutcome.userWin,
                              highlightLoss: _reveal?.outcome ==
                                  TrumpRoundOutcome.cpuWin,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCardView(
                              title: 'CPU',
                              card: showCpu ? cpuCard : null,
                              accent: GameColors.coral,
                              activeStats: widget.activeStats,
                              faceDown: !showCpu,
                              active: (!_engine.userChooses &&
                                      !_resolving &&
                                      !_engine.isOver) ||
                                  (_resolving &&
                                      _reveal?.outcome ==
                                          TrumpRoundOutcome.cpuWin),
                              highlightStat: _reveal?.stat,
                              highlightWin: _reveal?.outcome ==
                                  TrumpRoundOutcome.cpuWin,
                              highlightLoss: _reveal?.outcome ==
                                  TrumpRoundOutcome.userWin,
                            ),
                          ),
                        ],
                      ),
                      if (_reveal != null) ...[
                        const SizedBox(height: 14),
                        _RoundResultBanner(
                          result: _reveal!,
                          calledByUser: _callerWasUser,
                          cardsInPlay: _cardsInPlay,
                        ),
                      ],
                      if (_engine.isOver) ...[
                        const SizedBox(height: 16),
                        NeonButton(
                          label: 'PLAY AGAIN',
                          color: GameColors.magenta,
                          onPressed: _newMatch,
                        ),
                        const SizedBox(height: 8),
                        NeonButton(
                          label: _unlockedNext
                              ? 'BACK TO LEVELS'
                              : 'BACK',
                          outlined: true,
                          color: GameColors.mute,
                          onPressed: () =>
                              Navigator.of(context).maybePop(),
                        ),
                      ] else if (yourTurn) ...[
                        const SizedBox(height: 14),
                        Text(
                          'YOUR CALL — TAP A STAT',
                          style: hudLabelStyle(
                            color: GameColors.gold,
                            size: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final stat in widget.activeStats)
                              SizedBox(
                                width:
                                    (MediaQuery.sizeOf(context).width -
                                            48) /
                                        2,
                                child: NeonButton(
                                  label:
                                      '${stat.shortLabel}  ${userCard?.displayOf(stat) ?? '-'}',
                                  outlined: true,
                                  color: GameColors.magenta,
                                  height: 42,
                                  onPressed: () => _play(
                                    stat,
                                    calledByUser: true,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ] else if (_resolving &&
                          !_callerWasUser &&
                          _reveal == null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'CPU is picking a stat…',
                              textAlign: TextAlign.center,
                              style: hudLabelStyle(
                                color: GameColors.coral,
                                size: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTimerChip extends StatelessWidget {
  const _LiveTimerChip({
    required this.elapsed,
    required this.running,
  });

  final Duration elapsed;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GameColors.gold.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            running ? Icons.timer_outlined : Icons.timer_off_outlined,
            size: 14,
            color: GameColors.gold,
          ),
          const SizedBox(width: 5),
          Text(
            TrumpProgression.formatDuration(elapsed),
            style: const TextStyle(
              color: GameColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.userCards,
    required this.cpuCards,
    required this.potCards,
  });

  final int userCards;
  final int cpuCards;
  final int potCards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScoreChip(
            label: 'YOU',
            value: '$userCards',
            color: GameColors.cyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ScoreChip(
            label: 'POT',
            value: '$potCards',
            color: GameColors.gold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ScoreChip(
            label: 'CPU',
            value: '$cpuCards',
            color: GameColors.coral,
          ),
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Column(
        children: [
          Text(label, style: hudLabelStyle(color: color, size: 9)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          Text(
            'cards',
            style: hudLabelStyle(color: GameColors.mute, size: 8),
          ),
        ],
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({
    required this.isOver,
    required this.userWon,
    required this.yourTurn,
    required this.resolving,
    required this.userChooses,
  });

  final bool isOver;
  final bool userWon;
  final bool yourTurn;
  final bool resolving;
  final bool userChooses;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String title;
    late final String subtitle;

    if (isOver) {
      color = userWon ? GameColors.lime : GameColors.coral;
      title = userWon ? 'MATCH OVER — YOU WIN' : 'MATCH OVER — CPU WINS';
      subtitle = userWon ? 'Deck cleared. Nice battle.' : 'CPU took the last cards.';
    } else if (resolving) {
      color = GameColors.gold;
      title = 'COMPARING STATS…';
      subtitle = 'Watch both cards — winner takes them.';
    } else if (yourTurn) {
      color = GameColors.cyan;
      title = 'YOUR TURN';
      subtitle = 'Pick one stat from your card to challenge CPU.';
    } else if (!userChooses) {
      color = GameColors.coral;
      title = "CPU'S TURN";
      subtitle = 'CPU will call a stat from its hidden card.';
    } else {
      color = GameColors.mute;
      title = 'GET READY';
      subtitle = '';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.7), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            yourTurn
                ? Icons.touch_app_rounded
                : (resolving
                    ? Icons.compare_arrows_rounded
                    : Icons.smart_toy_rounded),
            color: color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.6,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: GameColors.mute,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundResultBanner extends StatelessWidget {
  const _RoundResultBanner({
    required this.result,
    required this.calledByUser,
    required this.cardsInPlay,
  });

  final TrumpRoundResult result;
  final bool calledByUser;
  final int cardsInPlay;

  @override
  Widget build(BuildContext context) {
    final u = result.userCard.displayOf(result.stat);
    final c = result.cpuCard.displayOf(result.stat);
    final caller = calledByUser ? 'YOU' : 'CPU';

    late final Color color;
    late final String headline;
    late final String detail;

    switch (result.outcome) {
      case TrumpRoundOutcome.userWin:
        color = GameColors.lime;
        headline = 'YOU WIN THIS ROUND';
        detail =
            '$caller called ${result.stat.label}. $u beats $c — you take $cardsInPlay card${cardsInPlay == 1 ? '' : 's'}.';
      case TrumpRoundOutcome.cpuWin:
        color = GameColors.coral;
        headline = 'CPU WINS THIS ROUND';
        detail =
            '$caller called ${result.stat.label}. $c beats $u — CPU takes $cardsInPlay card${cardsInPlay == 1 ? '' : 's'}.';
      case TrumpRoundOutcome.tie:
        color = GameColors.gold;
        headline = 'TIE — CARDS TO THE POT';
        detail =
            '$caller called ${result.stat.label}. $u = $c — both cards stay in the pot.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.6),
      ),
      child: Column(
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.stat.label.toUpperCase()}',
            style: hudLabelStyle(color: GameColors.text, size: 10),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ValuePill(
                  label: 'YOU',
                  value: u,
                  color: GameColors.cyan,
                  won: result.outcome == TrumpRoundOutcome.userWin,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: hudLabelStyle(color: GameColors.mute, size: 10),
                ),
              ),
              Expanded(
                child: _ValuePill(
                  label: 'CPU',
                  value: c,
                  color: GameColors.coral,
                  won: result.outcome == TrumpRoundOutcome.cpuWin,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameColors.text,
              fontWeight: FontWeight.w700,
              height: 1.35,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({
    required this.label,
    required this.value,
    required this.color,
    required this.won,
  });

  final String label;
  final String value;
  final Color color;
  final bool won;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: (won ? GameColors.lime : color).withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: won ? GameColors.lime : color.withOpacity(0.55),
          width: won ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: hudLabelStyle(color: color, size: 9)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: won ? GameColors.lime : GameColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardView extends StatelessWidget {
  const _StatCardView({
    required this.title,
    required this.card,
    required this.accent,
    required this.activeStats,
    this.faceDown = false,
    this.active = false,
    this.highlightStat,
    this.highlightWin = false,
    this.highlightLoss = false,
  });

  final String title;
  final TrumpCard? card;
  final Color accent;
  final List<TrumpStat> activeStats;
  final bool faceDown;
  final bool active;
  final TrumpStat? highlightStat;
  final bool highlightWin;
  final bool highlightLoss;

  @override
  Widget build(BuildContext context) {
    final glow = highlightWin
        ? GameColors.lime
        : (highlightLoss
            ? GameColors.coral.withOpacity(0.55)
            : (active ? accent : accent.withOpacity(0.45)));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: panelDecoration(glow: glow).copyWith(
        border: Border.all(
          color: active || highlightWin ? glow : GameColors.panelBorder,
          width: active || highlightWin ? 1.8 : 1,
        ),
      ),
      child: faceDown || card == null
          ? SizedBox(
              height: (120 + activeStats.length * 22.0).clamp(180.0, 420.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: hudLabelStyle(color: accent, size: 10)),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.style_rounded,
                    color: accent.withOpacity(0.7),
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    faceDown ? 'HIDDEN' : 'NO CARD',
                    style: hudLabelStyle(color: GameColors.mute, size: 11),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: hudLabelStyle(color: accent, size: 10)),
                    if (active) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: hudLabelStyle(color: accent, size: 8),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card!.name,
                  style: const TextStyle(
                    color: GameColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card!.teamShort,
                  style: hudLabelStyle(color: GameColors.gold, size: 10),
                ),
                const SizedBox(height: 10),
                for (final stat in activeStats)
                  _StatRow(
                    stat: stat,
                    valueLabel: card!.displayOf(stat),
                    highlighted: highlightStat == stat,
                    won: highlightWin && highlightStat == stat,
                    lost: highlightLoss && highlightStat == stat,
                  ),
              ],
            ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.stat,
    required this.valueLabel,
    required this.highlighted,
    required this.won,
    required this.lost,
  });

  final TrumpStat stat;
  final String valueLabel;
  final bool highlighted;
  final bool won;
  final bool lost;

  @override
  Widget build(BuildContext context) {
    final color = won
        ? GameColors.lime
        : (lost
            ? GameColors.coral
            : (highlighted ? GameColors.gold : GameColors.mute));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: highlighted
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
            : EdgeInsets.zero,
        decoration: highlighted
            ? BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                stat.shortLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperBit {
  _PaperBit({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.spin,
    required this.wobble,
    required this.rect,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double spin;
  final double wobble;
  final bool rect;

  factory _PaperBit.random(Random random) {
    const palette = <Color>[
      GameColors.gold,
      GameColors.cyan,
      GameColors.magenta,
      GameColors.lime,
      GameColors.coral,
      Color(0xFFFFF4C2),
      Color(0xFF8B5CFF),
    ];
    return _PaperBit(
      x: random.nextDouble(),
      delay: random.nextDouble(),
      speed: 0.35 + random.nextDouble() * 0.65,
      size: 5 + random.nextDouble() * 9,
      color: palette[random.nextInt(palette.length)],
      spin: (random.nextDouble() - 0.5) * 8,
      wobble: 12 + random.nextDouble() * 28,
      rect: random.nextBool(),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.bits, required this.t});

  final List<_PaperBit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final bit in bits) {
      final phase = (t * bit.speed + bit.delay) % 1.0;
      final y = -30 + phase * (size.height + 60);
      final x = bit.x * size.width +
          sin((t + bit.delay) * pi * 2 * bit.spin) * bit.wobble;
      final paint = Paint()..color = bit.color.withOpacity(0.88);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t + bit.delay) * bit.spin);
      if (bit.rect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: bit.size * 1.7,
              height: bit.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, bit.size * 0.45, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
