import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/screens/cricket_result_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketMatchScreen extends StatefulWidget {
  const CricketMatchScreen({
    super.key,
    required this.result,
    this.skipToss = false,
  });

  final MatchResult result;
  final bool skipToss;

  static Route<void> route(MatchResult result, {bool skipToss = false}) {
    return FadeScaleRoute(
      page: CricketMatchScreen(result: result, skipToss: skipToss),
    );
  }

  @override
  State<CricketMatchScreen> createState() => _CricketMatchScreenState();
}

class _CricketMatchScreenState extends State<CricketMatchScreen> {
  MatchPhase _phase = MatchPhase.toss;
  int _overIndex = 0;
  Timer? _timer;
  OverPulse? _currentOver;
  final List<String> _ballByBall = [];

  MatchResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.skipToss) {
        _beginFirstInnings();
      } else {
        _startToss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startToss() {
    setState(() {
      _phase = MatchPhase.toss;
      _currentOver = null;
      _ballByBall
        ..clear()
        ..add(result.tossSummary)
        ..add(
          result.userBattedFirst
              ? '${result.userTeamName} will open the batting.'
              : '${result.cpuTeamName} will open the batting.',
        );
    });
    _timer = Timer(const Duration(milliseconds: 2200), _beginFirstInnings);
  }

  void _beginFirstInnings() {
    setState(() {
      _phase = MatchPhase.firstInningsLive;
      _overIndex = 0;
      _ballByBall
        ..clear()
        ..add('First innings underway. Play!');
    });
    _playNextOver(result.firstInningsOvers, onComplete: _showInningsBreak);
  }

  void _showInningsBreak() {
    final first = result.firstInnings;
    setState(() {
      _phase = MatchPhase.inningsBreak;
      _timer?.cancel();
      _ballByBall
        ..clear()
        ..add('Innings closed at ${first.runs}/${first.wickets}.')
        ..add(
          result.userBattedFirst
              ? '${result.cpuTeamName} need ${first.runs + 1} to win.'
              : '${result.userTeamName} need ${first.runs + 1} to win.',
        );
    });
  }

  void _beginSecondInnings() {
    setState(() {
      _phase = MatchPhase.secondInningsLive;
      _overIndex = 0;
      _ballByBall
        ..clear()
        ..add('Chase begins. Required ${result.firstInnings.runs + 1}.');
    });
    _playNextOver(result.secondInningsOvers, onComplete: _finishMatch);
  }

  void _finishMatch() {
    setState(() => _phase = MatchPhase.finished);
    _timer?.cancel();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CricketResultScreen.route(result),
      );
    });
  }

  void _playNextOver(List<OverPulse> overs, {required VoidCallback onComplete}) {
    _timer?.cancel();
    if (_overIndex >= overs.length) {
      onComplete();
      return;
    }

    final pulse = overs[_overIndex];
    setState(() {
      _currentOver = pulse;
      _ballByBall.insert(
        0,
        'Over ${pulse.overNumber}: ${pulse.runsInOver} run${pulse.runsInOver == 1 ? '' : 's'}'
        '${pulse.wicketsInOver > 0 ? ', ${pulse.wicketsInOver} wicket${pulse.wicketsInOver == 1 ? '' : 's'}' : ''}'
        ' — ${pulse.highlights.take(2).join(' · ')}',
      );
      if (_ballByBall.length > 8) {
        _ballByBall.removeRange(8, _ballByBall.length);
      }
    });

    _overIndex += 1;
    _timer = Timer(const Duration(milliseconds: 650), () {
      _playNextOver(overs, onComplete: onComplete);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pulse = _currentOver;
    final first = result.firstInnings;
    final isBreak = _phase == MatchPhase.inningsBreak;
    final isToss = _phase == MatchPhase.toss;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${result.format.label} LIVE',
                  style: hudLabelStyle(color: GameColors.lime, size: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _phaseTitle,
                  style: const TextStyle(
                    color: GameColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _phaseSubtitle,
                  style: const TextStyle(
                    color: GameColors.mute,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: panelDecoration(glow: GameColors.lime),
                  child: Column(
                    children: [
                      Text(
                        pulse?.battingTeam ??
                            (result.userBattedFirst
                                ? result.userTeamName
                                : result.cpuTeamName),
                        style: hudLabelStyle(color: GameColors.lime, size: 10),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pulse?.scoreline ??
                            (isToss
                                ? 'TOSS IN PROGRESS'
                                : '${first.runs}/${first.wickets} (${first.oversLabel} ov)'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GameColors.text,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (pulse != null) ...[
                        Text(
                          'CRR ${pulse.runRate.toStringAsFixed(2)}'
                          '${pulse.requiredRunRate != null ? '  •  RRR ${pulse.requiredRunRate!.clamp(0, 36).toStringAsFixed(2)}' : ''}',
                          style: const TextStyle(
                            color: GameColors.mute,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Strike: ${pulse.striker.split(' ').last}  •  Over from ${pulse.bowler.split(' ').last}',
                          textAlign: TextAlign.center,
                          style: hudLabelStyle(size: 9),
                        ),
                      ] else if (isBreak) ...[
                        Text(
                          'Target for the chase: ${first.runs + 1}',
                          style: const TextStyle(
                            color: GameColors.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (pulse != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: panelDecoration(glow: GameColors.cyan),
                    child: Row(
                      children: [
                        Text(
                          'OVER ${pulse.overNumber}',
                          style: hudLabelStyle(color: GameColors.cyan, size: 10),
                        ),
                        const Spacer(),
                        Text(
                          '+${pulse.runsInOver}'
                          '${pulse.wicketsInOver > 0 ? ' & ${pulse.wicketsInOver} W' : ''}',
                          style: const TextStyle(
                            color: GameColors.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: panelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMENTARY',
                          style: hudLabelStyle(size: 10),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _ballByBall.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return Text(
                                _ballByBall[index],
                                style: TextStyle(
                                  color: index == 0
                                      ? GameColors.text
                                      : GameColors.mute,
                                  fontWeight: index == 0
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  height: 1.35,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isBreak) ...[
                  const SizedBox(height: 14),
                  NeonButton(
                    label: 'START THE CHASE',
                    color: GameColors.lime,
                    onPressed: _beginSecondInnings,
                  ),
                ],
                if (_phase == MatchPhase.finished) ...[
                  const SizedBox(height: 14),
                  Text(
                    'STUMPS… PREPARING THE RESULT',
                    textAlign: TextAlign.center,
                    style: hudLabelStyle(color: GameColors.gold, size: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _phaseTitle {
    switch (_phase) {
      case MatchPhase.toss:
        return 'TOSS TIME';
      case MatchPhase.firstInningsLive:
        return 'FIRST INNINGS';
      case MatchPhase.inningsBreak:
        return 'INNINGS BREAK';
      case MatchPhase.secondInningsLive:
        return 'THE CHASE';
      case MatchPhase.finished:
        return 'STUMPS';
    }
  }

  String get _phaseSubtitle {
    switch (_phase) {
      case MatchPhase.toss:
        return result.tossSummary;
      case MatchPhase.firstInningsLive:
        return 'Overs ticking over. Watch the scoreboard climb.';
      case MatchPhase.inningsBreak:
        return 'Change of innings. Pads on for the chase.';
      case MatchPhase.secondInningsLive:
        return 'Hunting the target under the lights.';
      case MatchPhase.finished:
        return result.matchSummary;
    }
  }
}
