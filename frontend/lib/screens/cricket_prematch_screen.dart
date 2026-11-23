import 'dart:math';

import 'package:flutter/material.dart';
import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/cricket/match_history.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/venues.dart';
import 'package:guess_game/screens/cricket_match_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

enum _PrematchStep { choice, toss, lineups }

class CricketPrematchScreen extends StatefulWidget {
  const CricketPrematchScreen({
    super.key,
    required this.format,
    required this.userSquad,
    required this.cpuSquad,
  });

  final CricketFormat format;
  final Squad userSquad;
  final Squad cpuSquad;

  static Route<void> route({
    required CricketFormat format,
    required Squad userSquad,
    required Squad cpuSquad,
  }) {
    return FadeScaleRoute(
      page: CricketPrematchScreen(
        format: format,
        userSquad: userSquad,
        cpuSquad: cpuSquad,
      ),
    );
  }

  @override
  State<CricketPrematchScreen> createState() => _CricketPrematchScreenState();
}

class _CricketPrematchScreenState extends State<CricketPrematchScreen> {
  final _random = Random();
  late final CricketVenue _venue = pickVenue(_random);
  _PrematchStep _step = _PrematchStep.choice;
  bool? _userWantsToBat;
  bool? _tossWinnerIsUser;
  bool? _electedToBat;
  bool? _userBatsFirst;
  List<MatchHistoryEntry> _form = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    MatchHistoryStore.latest().then((entries) {
      if (!mounted) return;
      setState(() => _form = entries);
    });
  }

  void _choose(bool batFirst) {
    final tossWinnerIsUser = _random.nextBool();
    final bool electedToBat;
    final bool userBatsFirst;
    if (tossWinnerIsUser) {
      electedToBat = batFirst;
      userBatsFirst = batFirst;
    } else {
      electedToBat = _random.nextBool();
      userBatsFirst = !electedToBat;
    }
    setState(() {
      _userWantsToBat = batFirst;
      _tossWinnerIsUser = tossWinnerIsUser;
      _electedToBat = electedToBat;
      _userBatsFirst = userBatsFirst;
      _step = _PrematchStep.toss;
    });
  }

  Future<void> _takeTheField() async {
    if (_userWantsToBat == null ||
        _tossWinnerIsUser == null ||
        _electedToBat == null) {
      return;
    }
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final result = MatchEngine(random: _random).play(
      format: widget.format,
      userSquad: widget.userSquad,
      cpuSquad: widget.cpuSquad,
      userWantsToBat: _userWantsToBat!,
      tossWinnerIsUser: _tossWinnerIsUser,
      electedToBat: _electedToBat,
      venue: _venue,
    );

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      CricketMatchScreen.route(result, skipToss: true),
    );
  }

  String get _tossHeadline {
    if (_tossWinnerIsUser == true) {
      return 'YOU WON THE TOSS';
    }
    return 'RIVAL WON THE TOSS';
  }

  String get _tossDetail {
    final winner = _tossWinnerIsUser == true ? 'Your XI' : 'Rival XI';
    final choice = _electedToBat == true ? 'bat' : 'bowl';
    final preference = _userWantsToBat == true ? 'bat' : 'bowl';
    if (_tossWinnerIsUser == true) {
      return '$winner elected to $choice first — matching your call to $preference.';
    }
    return '$winner elected to $choice first. Your call was to $preference.';
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
                Text(
                  '${widget.format.label} MATCH CENTRE',
                  style: hudLabelStyle(color: GameColors.lime, size: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == _PrematchStep.choice
                      ? 'CAPTAIN\'S CALL'
                      : (_step == _PrematchStep.toss
                          ? 'TOSS COMPLETE'
                          : 'PLAYING XIs'),
                  style: const TextStyle(
                    color: GameColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      _VenueCard(venue: _venue),
                      const SizedBox(height: 12),
                      _FormCard(entries: _form),
                      const SizedBox(height: 12),
                      if (_step == _PrematchStep.choice) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: panelDecoration(glow: GameColors.gold),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'IF YOU WIN THE TOSS…',
                                style: hudLabelStyle(
                                  color: GameColors.gold,
                                  size: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Make your captain\'s call before the coin goes up.',
                                style: TextStyle(
                                  color: GameColors.mute,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              NeonButton(
                                label: 'BAT FIRST',
                                color: GameColors.lime,
                                onPressed: () => _choose(true),
                              ),
                              const SizedBox(height: 10),
                              NeonButton(
                                label: 'BOWL FIRST',
                                outlined: true,
                                color: GameColors.cyan,
                                onPressed: () => _choose(false),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_step == _PrematchStep.toss ||
                          _step == _PrematchStep.lineups) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: panelDecoration(glow: GameColors.cyan),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tossHeadline,
                                style: hudLabelStyle(
                                  color: GameColors.cyan,
                                  size: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _tossDetail,
                                style: const TextStyle(
                                  color: GameColors.text,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userBatsFirst == true
                                    ? 'Your XI will open the batting.'
                                    : 'Your XI will bowl first and chase later.',
                                style: const TextStyle(color: GameColors.mute),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_step == _PrematchStep.lineups) ...[
                        const SizedBox(height: 12),
                        _XiCard(
                          title: 'YOUR PLAYING XI',
                          squad: widget.userSquad,
                          accent: GameColors.lime,
                        ),
                        const SizedBox(height: 12),
                        _XiCard(
                          title: 'RIVAL PLAYING XI',
                          squad: widget.cpuSquad,
                          accent: GameColors.magenta,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_step == _PrematchStep.toss) ...[
                  NeonButton(
                    label: 'REVEAL PLAYING XIs',
                    color: GameColors.lime,
                    onPressed: () =>
                        setState(() => _step = _PrematchStep.lineups),
                  ),
                ],
                if (_step == _PrematchStep.lineups) ...[
                  NeonButton(
                    label: _busy ? 'WALKING OUT…' : 'TAKE THE FIELD',
                    color: GameColors.lime,
                    onPressed: _busy ? null : _takeTheField,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue});

  final CricketVenue venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(glow: GameColors.lime),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VENUE', style: hudLabelStyle(color: GameColors.lime, size: 9)),
          const SizedBox(height: 8),
          Text(
            venue.headline,
            style: const TextStyle(
              color: GameColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${venue.country}  •  Cap. ${venue.capacity}',
            style: const TextStyle(color: GameColors.mute, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text('PITCH REPORT', style: hudLabelStyle(size: 9)),
          const SizedBox(height: 6),
          Text(
            venue.pitchReport,
            style: const TextStyle(color: GameColors.text, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${venue.outfieldNote} Weather: ${venue.weather}.',
            style: const TextStyle(color: GameColors.mute, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.entries});

  final List<MatchHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR LAST 5 RESULTS',
            style: hudLabelStyle(size: 9),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Text(
              'No recent fixtures yet. This is a fresh page in the book.',
              style: TextStyle(color: GameColors.mute, height: 1.4),
            )
          else
            ...entries.map((entry) {
              final tag = entry.tied
                  ? 'TIE'
                  : (entry.userWon ? 'WON' : 'LOST');
              final color = entry.tied
                  ? GameColors.cyan
                  : (entry.userWon ? GameColors.lime : GameColors.coral);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color),
                        color: color.withOpacity(0.12),
                      ),
                      child: Text(
                        tag,
                        style: hudLabelStyle(color: color, size: 9),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.scoreline,
                            style: const TextStyle(
                              color: GameColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.venueName}  •  ${entry.summary}',
                            style: const TextStyle(
                              color: GameColors.mute,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
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

class _XiCard extends StatelessWidget {
  const _XiCard({
    required this.title,
    required this.squad,
    required this.accent,
  });

  final String title;
  final Squad squad;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(glow: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: hudLabelStyle(color: accent, size: 10)),
          const SizedBox(height: 10),
          ...squad.picks.map((pick) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${pick.slot.index + 1}.',
                      style: hudLabelStyle(size: 9),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pick.player.name,
                      style: const TextStyle(
                        color: GameColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    pick.slot.label,
                    style: hudLabelStyle(color: accent, size: 8),
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
