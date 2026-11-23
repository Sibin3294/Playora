import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guess_game/cricket/ipl_roster.dart';
import 'package:guess_game/cricket/league_engine.dart';
import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/screens/cricket_league_champion_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

enum _SeasonPhase {
  loading,
  leagueMatch,
  leagueProgress,
  standings,
  playoffMatch,
  playoffProgress,
  eliminated,
  champion,
}

class CricketLeagueSeasonScreen extends StatefulWidget {
  const CricketLeagueSeasonScreen({
    super.key,
    required this.competition,
    required this.userTeam,
    required this.userSquad,
  });

  final LeagueCompetition competition;
  final CricketTeam userTeam;
  final Squad userSquad;

  static Route<void> route({
    required LeagueCompetition competition,
    required CricketTeam userTeam,
    required Squad userSquad,
  }) {
    return FadeScaleRoute(
      page: CricketLeagueSeasonScreen(
        competition: competition,
        userTeam: userTeam,
        userSquad: userSquad,
      ),
    );
  }

  @override
  State<CricketLeagueSeasonScreen> createState() =>
      _CricketLeagueSeasonScreenState();
}

class _CricketLeagueSeasonScreenState extends State<CricketLeagueSeasonScreen> {
  static const _matchDwell = Duration(milliseconds: 2600);
  static const _progressDwell = Duration(milliseconds: 1500);
  static const _standingsDwell = Duration(milliseconds: 3200);

  LeagueSeasonOutcome? _season;
  _SeasonPhase _phase = _SeasonPhase.loading;
  int _leagueIndex = 0;
  int _playoffIndex = 0;
  String? _error;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _runSeason();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _scheduleAuto(Duration delay, FutureOr<void> Function() action) {
    _autoTimer?.cancel();
    _autoTimer = Timer(delay, () async {
      if (!mounted) return;
      await action();
    });
  }

  Future<void> _runSeason() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      final season = LeagueEngine().simulate(
        competition: widget.competition,
        userTeam: widget.userTeam,
        userSquad: widget.userSquad,
      );
      if (!mounted) return;
      setState(() {
        _season = season;
        _phase = season.userLeagueMatches.isEmpty
            ? _SeasonPhase.standings
            : _SeasonPhase.leagueMatch;
        _leagueIndex = 0;
      });
      if (season.userLeagueMatches.isEmpty) {
        _scheduleAuto(_standingsDwell, _continueFromStandings);
      } else {
        _scheduleAuto(_matchDwell, _nextAfterLeagueMatch);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _nextAfterLeagueMatch() async {
    final season = _season!;
    if (_leagueIndex < season.userLeagueMatches.length - 1) {
      setState(() => _phase = _SeasonPhase.leagueProgress);
      _scheduleAuto(_progressDwell, _revealNextLeagueMatch);
      return;
    }
    setState(() => _phase = _SeasonPhase.standings);
    _scheduleAuto(_standingsDwell, _continueFromStandings);
  }

  Future<void> _revealNextLeagueMatch() async {
    setState(() {
      _leagueIndex += 1;
      _phase = _SeasonPhase.leagueMatch;
    });
    _scheduleAuto(_matchDwell, _nextAfterLeagueMatch);
  }

  Future<void> _continueFromStandings() async {
    final season = _season!;
    if (!season.userQualified) {
      setState(() => _phase = _SeasonPhase.eliminated);
      return;
    }
    if (season.userPlayoffMatches.isEmpty) {
      setState(() => _phase = _SeasonPhase.eliminated);
      return;
    }
    setState(() {
      _phase = _SeasonPhase.playoffMatch;
      _playoffIndex = 0;
    });
    _scheduleAuto(_matchDwell, _nextAfterPlayoffMatch);
  }

  Future<void> _nextAfterPlayoffMatch() async {
    final season = _season!;
    final match = season.userPlayoffMatches[_playoffIndex];

    // Q1 losers still reach Qualifier 2. Only these stages can end the run.
    final knockoutLoss = !match.tied &&
        !match.userWon &&
        (match.stage == LeagueStage.eliminator ||
            match.stage == LeagueStage.qualifier2 ||
            match.stage == LeagueStage.finalMatch);

    if (knockoutLoss) {
      setState(() => _phase = _SeasonPhase.eliminated);
      return;
    }

    if (_playoffIndex < season.userPlayoffMatches.length - 1) {
      setState(() => _phase = _SeasonPhase.playoffProgress);
      _scheduleAuto(_progressDwell, _revealNextPlayoffMatch);
      return;
    }

    if (season.userChampion) {
      setState(() => _phase = _SeasonPhase.champion);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CricketLeagueChampionScreen.route(
          competitionName: season.competition.name,
          franchise: season.userTeam,
        ),
      );
      return;
    }

    setState(() => _phase = _SeasonPhase.eliminated);
  }

  Future<void> _revealNextPlayoffMatch() async {
    setState(() {
      _playoffIndex += 1;
      _phase = _SeasonPhase.playoffMatch;
    });
    _scheduleAuto(_matchDwell, _nextAfterPlayoffMatch);
  }

  bool get _canSkip =>
      _season != null &&
      (_phase == _SeasonPhase.leagueMatch ||
          _phase == _SeasonPhase.leagueProgress ||
          _phase == _SeasonPhase.playoffMatch ||
          _phase == _SeasonPhase.playoffProgress ||
          _phase == _SeasonPhase.standings);

  String _opponentShort(LeagueMatchCard match) {
    if (match.homeId == widget.userTeam.id) return match.awayShort;
    if (match.awayId == widget.userTeam.id) return match.homeShort;
    return match.awayShort;
  }

  Future<void> _skipToFinalResult() async {
    if (!_canSkip) return;
    _autoTimer?.cancel();
    final season = _season!;

    if (season.userChampion) {
      setState(() => _phase = _SeasonPhase.champion);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CricketLeagueChampionScreen.route(
          competitionName: season.competition.name,
          franchise: season.userTeam,
        ),
      );
      return;
    }

    setState(() => _phase = _SeasonPhase.eliminated);
  }

  @override
  Widget build(BuildContext context) {
    final season = _season;

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
                    Expanded(
                      child: Text(
                        '${widget.userTeam.shortName} • ${widget.competition.name.toUpperCase()}',
                        style: hudLabelStyle(color: GameColors.lime, size: 11),
                      ),
                    ),
                    if (_canSkip)
                      TextButton(
                        onPressed: _skipToFinalResult,
                        style: TextButton.styleFrom(
                          foregroundColor: GameColors.gold,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          'SKIP',
                          style: hudLabelStyle(color: GameColors.gold, size: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _title,
                  style: const TextStyle(
                    color: GameColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GameColors.coral,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : switch (_phase) {
                          _SeasonPhase.loading => const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: GameColors.lime,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'AUTOPLAYING THE SEASON…',
                                    style: TextStyle(
                                      color: GameColors.mute,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _SeasonPhase.leagueMatch => _MatchResultView(
                              match: season!.userLeagueMatches[_leagueIndex],
                              progress:
                                  'MATCH ${_leagueIndex + 1}/${season.userLeagueMatches.length}',
                              matches: season.userLeagueMatches,
                              completedMatches: _leagueIndex + 1,
                            ),
                          _SeasonPhase.leagueProgress => _MatchProgressView(
                              progress:
                                  'MATCH ${_leagueIndex + 2}/${season!.userLeagueMatches.length}',
                              matches: season.userLeagueMatches,
                              completedMatches: _leagueIndex + 1,
                              activeMatch: _leagueIndex + 2,
                              opponentLabel: _opponentShort(
                                season.userLeagueMatches[_leagueIndex + 1],
                              ),
                              stageLabel: 'LEAGUE',
                            ),
                          _SeasonPhase.standings => _StandingsView(
                              rows: season!.standings,
                              userQualified: season.userQualified,
                            ),
                          _SeasonPhase.playoffMatch => _MatchResultView(
                              match: season!.userPlayoffMatches[_playoffIndex],
                              progress:
                                  '${season.userPlayoffMatches[_playoffIndex].stage.label}  •  ${_playoffIndex + 1}/${season.userPlayoffMatches.length}',
                              matches: season.userPlayoffMatches,
                              completedMatches: _playoffIndex + 1,
                            ),
                          _SeasonPhase.playoffProgress => _MatchProgressView(
                              progress:
                                  '${season!.userPlayoffMatches[_playoffIndex + 1].stage.label}  •  ${_playoffIndex + 2}/${season.userPlayoffMatches.length}',
                              matches: season.userPlayoffMatches,
                              completedMatches: _playoffIndex + 1,
                              activeMatch: _playoffIndex + 2,
                              opponentLabel: _opponentShort(
                                season.userPlayoffMatches[_playoffIndex + 1],
                              ),
                              stageLabel: season
                                  .userPlayoffMatches[_playoffIndex + 1]
                                  .stage
                                  .label,
                            ),
                          _SeasonPhase.eliminated => _EliminatedView(
                              season: season!,
                            ),
                          _SeasonPhase.champion => const Center(
                              child: Text(
                                'RAISING THE CUP…',
                                style: TextStyle(
                                  color: GameColors.gold,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                        },
                ),
                if (_phase == _SeasonPhase.leagueMatch ||
                    _phase == _SeasonPhase.leagueProgress ||
                    _phase == _SeasonPhase.playoffMatch ||
                    _phase == _SeasonPhase.playoffProgress ||
                    _phase == _SeasonPhase.standings) ...[
                  Text(
                    _phase == _SeasonPhase.standings
                        ? 'AUTO-ADVANCING…'
                        : (_phase == _SeasonPhase.leagueProgress ||
                                _phase == _SeasonPhase.playoffProgress)
                            ? 'MATCH IN PROGRESS…'
                            : 'AUTOPLAYING FIXTURES…',
                    textAlign: TextAlign.center,
                    style: hudLabelStyle(color: GameColors.gold, size: 10),
                  ),
                ],
                if (_phase == _SeasonPhase.eliminated) ...[
                  NeonButton(
                    label: 'BACK TO THE HUB',
                    color: GameColors.cyan,
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    switch (_phase) {
      case _SeasonPhase.loading:
        return 'SEASON TIP-OFF';
      case _SeasonPhase.leagueMatch:
        return 'LEAGUE RESULT';
      case _SeasonPhase.leagueProgress:
        return 'NEXT FIXTURE';
      case _SeasonPhase.standings:
        return 'POINTS TABLE';
      case _SeasonPhase.playoffMatch:
        return 'PLAYOFF RESULT';
      case _SeasonPhase.playoffProgress:
        return 'NEXT KNOCKOUT';
      case _SeasonPhase.eliminated:
        return 'CAMPAIGN OVER';
      case _SeasonPhase.champion:
        return 'CHAMPIONS';
    }
  }
}

enum _SegmentResult { pending, active, won, lost, tied }

class _MatchSegmentStrip extends StatelessWidget {
  const _MatchSegmentStrip({
    required this.matches,
    required this.completed,
    this.activeMatch,
  });

  final List<LeagueMatchCard> matches;
  final int completed;
  /// 1-based index of the match currently in progress, if any.
  final int? activeMatch;

  _SegmentResult _resultFor(int index) {
    if (activeMatch == index + 1) return _SegmentResult.active;
    if (index >= completed) return _SegmentResult.pending;
    final match = matches[index];
    if (match.tied) return _SegmentResult.tied;
    return match.userWon ? _SegmentResult.won : _SegmentResult.lost;
  }

  @override
  Widget build(BuildContext context) {
    final total = matches.length;
    if (total <= 0) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _MatchSegmentChip(
              number: i + 1,
              result: _resultFor(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchSegmentChip extends StatelessWidget {
  const _MatchSegmentChip({
    required this.number,
    required this.result,
  });

  final int number;
  final _SegmentResult result;

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color fill;
    final Color text;
    switch (result) {
      case _SegmentResult.won:
        border = GameColors.lime;
        fill = GameColors.lime.withOpacity(0.22);
        text = GameColors.lime;
      case _SegmentResult.lost:
        border = GameColors.coral;
        fill = GameColors.coral.withOpacity(0.22);
        text = GameColors.coral;
      case _SegmentResult.tied:
        border = GameColors.gold;
        fill = GameColors.gold.withOpacity(0.2);
        text = GameColors.gold;
      case _SegmentResult.active:
        border = GameColors.cyan;
        fill = GameColors.cyan.withOpacity(0.2);
        text = GameColors.cyan;
      case _SegmentResult.pending:
        border = GameColors.panelBorder;
        fill = const Color(0xFF0A0F22);
        text = GameColors.mute;
    }

    final highlighted = result != _SegmentResult.pending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: highlighted ? 1.6 : 1.2),
        boxShadow: result == _SegmentResult.active
            ? [
                BoxShadow(
                  color: GameColors.cyan.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MatchProgressView extends StatefulWidget {
  const _MatchProgressView({
    required this.progress,
    required this.matches,
    required this.completedMatches,
    required this.activeMatch,
    required this.opponentLabel,
    required this.stageLabel,
  });

  final String progress;
  final List<LeagueMatchCard> matches;
  final int completedMatches;
  final int activeMatch;
  final String opponentLabel;
  final String stageLabel;

  @override
  State<_MatchProgressView> createState() => _MatchProgressViewState();
}

class _MatchProgressViewState extends State<_MatchProgressView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            widget.progress,
            style: hudLabelStyle(color: GameColors.gold, size: 10),
          ),
          const SizedBox(height: 12),
          _MatchSegmentStrip(
            matches: widget.matches,
            completed: widget.completedMatches,
            activeMatch: widget.activeMatch,
          ),
          const SizedBox(height: 22),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = _pulse.value;
              return Container(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                decoration: panelDecoration(
                  glow: Color.lerp(GameColors.cyan, GameColors.lime, t),
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                Text(
                  widget.stageLabel.toUpperCase(),
                  style: hudLabelStyle(color: GameColors.cyan, size: 10),
                ),
                const SizedBox(height: 14),
                const Icon(
                  Icons.sports_cricket_rounded,
                  color: GameColors.cyan,
                  size: 48,
                ),
                const SizedBox(height: 14),
                const Text(
                  'MATCH IN PROGRESS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'vs ${widget.opponentLabel}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return LinearProgressIndicator(
                        value: 0.35 + (_pulse.value * 0.45),
                        minHeight: 6,
                        backgroundColor: GameColors.panelBorder.withOpacity(0.45),
                        color: GameColors.cyan,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fixture ${widget.activeMatch} of ${widget.matches.length}',
                  style: hudLabelStyle(size: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchResultView extends StatelessWidget {
  const _MatchResultView({
    required this.match,
    required this.progress,
    required this.matches,
    required this.completedMatches,
  });

  final LeagueMatchCard match;
  final String progress;
  final List<LeagueMatchCard> matches;
  final int completedMatches;

  @override
  Widget build(BuildContext context) {
    final result = match.result;
    final accent = match.tied
        ? GameColors.cyan
        : (match.userWon ? GameColors.lime : GameColors.coral);

    return ListView(
      children: [
        Text(progress, style: hudLabelStyle(color: GameColors.gold, size: 10)),
        const SizedBox(height: 12),
        _MatchSegmentStrip(
          matches: matches,
          completed: completedMatches,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: panelDecoration(glow: accent),
          child: Column(
            children: [
              Text(
                match.stage.label,
                style: hudLabelStyle(color: accent, size: 10),
              ),
              const SizedBox(height: 8),
              Text(
                match.tied
                    ? 'MATCH TIED'
                    : (match.userWon ? 'YOU WON' : 'YOU LOST'),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                match.scoreline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GameColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                match.summary,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GameColors.mute, height: 1.35),
              ),
              const SizedBox(height: 8),
              Text(
                match.venueName,
                style: hudLabelStyle(size: 9),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MiniInnings(
          title: '1ST INNINGS • ${result.firstInnings.teamName}',
          card: result.firstInnings,
        ),
        const SizedBox(height: 10),
        _MiniInnings(
          title: '2ND INNINGS • ${result.secondInnings.teamName}',
          card: result.secondInnings,
        ),
      ],
    );
  }
}

class _MiniInnings extends StatelessWidget {
  const _MiniInnings({required this.title, required this.card});

  final String title;
  final InningsCard card;

  @override
  Widget build(BuildContext context) {
    final batters = card.batters.where((b) => b.balls > 0 || b.out).take(5);
    final bowlers = card.bowlers.where((b) => b.balls > 0).take(4);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: hudLabelStyle(size: 9)),
          const SizedBox(height: 8),
          Text(
            '${card.runs}/${card.wickets} (${card.oversLabel} ov)',
            style: const TextStyle(
              color: GameColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          for (final batter in batters)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      batter.player.name,
                      style: const TextStyle(
                        color: GameColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${batter.runs} (${batter.balls})',
                    style: const TextStyle(
                      color: GameColors.mute,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          for (final bowler in bowlers)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bowler.player.name,
                      style: const TextStyle(
                        color: GameColors.mute,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${bowler.wickets}/${bowler.runsConceded}',
                    style: hudLabelStyle(color: GameColors.gold, size: 9),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StandingsView extends StatelessWidget {
  const _StandingsView({
    required this.rows,
    required this.userQualified,
  });

  final List<LeagueStandingRow> rows;
  final bool userQualified;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: panelDecoration(
            glow: userQualified ? GameColors.lime : GameColors.coral,
          ),
          child: Text(
            userQualified
                ? 'Top four locked. Your franchise has made the playoffs.'
                : 'Outside the top four. The playoff road ends here.',
            style: TextStyle(
              color: userQualified ? GameColors.lime : GameColors.coral,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          decoration: panelDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('#', style: hudLabelStyle(size: 9)),
                  ),
                  Expanded(child: Text('TEAM', style: hudLabelStyle(size: 9))),
                  SizedBox(
                    width: 28,
                    child: Text('P', style: hudLabelStyle(size: 9), textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('W', style: hudLabelStyle(size: 9), textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('PTS', style: hudLabelStyle(size: 9), textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text('NRR', style: hudLabelStyle(size: 9), textAlign: TextAlign.right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < rows.length; i++) ...[
                _StandingRow(rank: i + 1, row: rows[i], playoffCut: i < 4),
                if (i == 3)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: GameColors.panelBorder, height: 1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rank,
    required this.row,
    required this.playoffCut,
  });

  final int rank;
  final LeagueStandingRow row;
  final bool playoffCut;

  @override
  Widget build(BuildContext context) {
    final color = row.isUser
        ? GameColors.lime
        : (playoffCut ? GameColors.text : GameColors.mute);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.isUser ? '${row.shortName} (YOU)' : row.shortName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${row.played}',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${row.won}',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${row.points}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              row.nrr.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EliminatedView extends StatelessWidget {
  const _EliminatedView({required this.season});

  final LeagueSeasonOutcome season;

  @override
  Widget build(BuildContext context) {
    final stage = season.eliminatedAt;
    final message = switch (stage) {
      LeagueStage.league =>
        'The league stage closed the door. Rebuild the XI and chase the cup next season.',
      LeagueStage.eliminator =>
        'Knocked out in the Eliminator. So close to the final four fight.',
      LeagueStage.qualifier1 =>
        'The Qualifier path slipped away. Another year, another hunt.',
      LeagueStage.qualifier2 =>
        'Beaten in Qualifier 2. The final stayed one win away.',
      LeagueStage.finalMatch =>
        'Runners-up. The trophy was within reach on the biggest night.',
      null => 'Campaign complete. The dressing room lights are out.',
    };

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: panelDecoration(glow: GameColors.magenta),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stage?.label ?? 'SEASON END',
              style: hudLabelStyle(color: GameColors.magenta, size: 11),
            ),
            const SizedBox(height: 12),
            Text(
              '${season.userTeam.shortName} ELIMINATED',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameColors.text,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GameColors.mute, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
