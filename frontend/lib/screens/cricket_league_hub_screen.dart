import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guess_game/cricket/ipl_roster.dart';
import 'package:guess_game/cricket/league_engine.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/screens/cricket_draft_screen.dart';
import 'package:guess_game/screens/cricket_league_season_screen.dart';
import 'package:guess_game/theme/game_theme.dart';
import 'package:guess_game/widgets/game_background.dart';
import 'package:guess_game/widgets/neon_button.dart';

class CricketLeagueHubScreen extends StatefulWidget {
  const CricketLeagueHubScreen({super.key});

  static Route<void> route() =>
      FadeScaleRoute(page: const CricketLeagueHubScreen());

  @override
  State<CricketLeagueHubScreen> createState() => _CricketLeagueHubScreenState();
}

class _CricketLeagueHubScreenState extends State<CricketLeagueHubScreen> {
  LeagueCompetition? _competition;
  final _nameController = TextEditingController(text: 'Playora XI');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startDraft() {
    final competition = _competition!;
    final userTeam = buildUserLeagueTeam(_nameController.text);
    Navigator.of(context).push(
      CricketDraftScreen.route(
        CricketFormat.t20,
        teamPool: competition.teams,
        headline: '${userTeam.shortName} DRAFT',
        maxOverseas: competition.maxOverseasPlayers,
        onDraftComplete: (ctx, squad) async {
          await Navigator.of(ctx).pushReplacement(
            CricketLeagueSeasonScreen.route(
              competition: competition,
              userTeam: userTeam,
              userSquad: squad,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final naming = _competition != null;

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
                      onPressed: () {
                        if (_competition != null) {
                          setState(() => _competition = null);
                          return;
                        }
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameColors.mute,
                      ),
                    ),
                    Text(
                      naming
                          ? _competition!.name.toUpperCase()
                          : 'LEAGUES',
                      style: hudLabelStyle(color: GameColors.lime, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  naming ? 'NAME YOUR\nTEAM' : 'PICK A\nCOMPETITION',
                  style: const TextStyle(
                    color: GameColors.text,
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  naming
                      ? 'Enter as a brand-new side and take on every franchise in the league.'
                      : 'Start with the IPL. More leagues can join this shelf later.',
                  style: const TextStyle(
                    color: GameColors.mute,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: naming
                      ? ListView(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration:
                                  panelDecoration(glow: GameColors.gold),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR NEW FRANCHISE',
                                    style: hudLabelStyle(
                                      color: GameColors.gold,
                                      size: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: GameColors.text,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                    cursorColor: GameColors.lime,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    maxLength: 24,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r"[A-Za-z0-9 '\-]"),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      counterStyle: hudLabelStyle(size: 9),
                                      hintText: 'Playora XI',
                                      hintStyle: const TextStyle(
                                        color: GameColors.mute,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF10182E),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: GameColors.panelBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: GameColors.lime,
                                          width: 1.4,
                                        ),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Short code: ${buildUserLeagueTeam(_nameController.text).shortName}',
                                    style: hudLabelStyle(
                                      color: GameColors.cyan,
                                      size: 9,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'You will draft an XI from IPL packs, then face all ${_competition!.teams.length} franchises in the league table.',
                                    style: const TextStyle(
                                      color: GameColors.mute,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            NeonButton(
                              label: 'START DRAFT',
                              color: GameColors.lime,
                              onPressed: _startDraft,
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            for (final league in t20Leagues) ...[
                              _LeagueTile(
                                competition: league,
                                onTap: () =>
                                    setState(() => _competition = league),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
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

class _LeagueTile extends StatelessWidget {
  const _LeagueTile({required this.competition, required this.onTap});

  final LeagueCompetition competition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: panelDecoration(glow: GameColors.lime),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    competition.name,
                    style: const TextStyle(
                      color: GameColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                Text(
                  '${competition.teams.length}+1 TEAMS',
                  style: hudLabelStyle(color: GameColors.lime, size: 9),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              competition.tagline,
              style: const TextStyle(color: GameColors.mute, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
