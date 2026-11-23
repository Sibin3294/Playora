import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_game/cricket/draft_engine.dart';
import 'package:guess_game/cricket/ipl_roster.dart';
import 'package:guess_game/cricket/league_engine.dart';

void main() {
  test('IPL season adds user as 11th side against all franchises', () {
    final userTeam = buildUserLeagueTeam('Neon Strikers');
    final userSquad = DraftEngine(
      teamPool: iplTeams,
      random: Random(7),
    ).buildCpuSquad();

    final season = LeagueEngine(random: Random(11)).simulate(
      competition: iplCompetition,
      userTeam: userTeam,
      userSquad: userSquad,
    );

    expect(userTeam.shortName, 'NS');
    expect(season.standings.length, 11);
    expect(season.userLeagueMatches.length, 10);
    expect(season.standings.every((row) => row.played == 10), isTrue);
    expect(season.leagueMatches.length, 55);
    expect(season.standings.where((row) => row.isUser).length, 1);
  });

  test('franchise XI fills all 11 slots', () {
    final xi = DraftEngine.buildFranchiseXi(iplTeams[2]);
    expect(xi.picks.length, 11);
    expect(xi.players.map((p) => p.id).toSet().length, 11);
  });
}
