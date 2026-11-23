import 'dart:math';

import 'package:guess_game/cricket/draft_engine.dart';
import 'package:guess_game/cricket/ipl_roster.dart';
import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/venues.dart';

enum LeagueStage {
  league('LEAGUE'),
  qualifier1('QUALIFIER 1'),
  eliminator('ELIMINATOR'),
  qualifier2('QUALIFIER 2'),
  finalMatch('FINAL');

  const LeagueStage(this.label);
  final String label;
}

class LeagueStandingRow {
  LeagueStandingRow({
    required this.teamId,
    required this.name,
    required this.shortName,
    required this.isUser,
  });

  final String teamId;
  final String name;
  final String shortName;
  final bool isUser;
  int played = 0;
  int won = 0;
  int lost = 0;
  int tied = 0;
  double runsFor = 0;
  double oversFaced = 0;
  double runsAgainst = 0;
  double oversBowled = 0;

  int get points => (won * 2) + tied;

  double get nrr {
    if (oversFaced <= 0 || oversBowled <= 0) return 0;
    return (runsFor / oversFaced) - (runsAgainst / oversBowled);
  }
}

class LeagueMatchCard {
  LeagueMatchCard({
    required this.id,
    required this.stage,
    required this.homeId,
    required this.awayId,
    required this.homeName,
    required this.awayName,
    required this.homeShort,
    required this.awayShort,
    required this.involvesUser,
    required this.result,
    required this.homeRuns,
    required this.homeWickets,
    required this.awayRuns,
    required this.awayWickets,
    required this.summary,
    required this.userWon,
    required this.tied,
    required this.venueName,
  });

  final String id;
  final LeagueStage stage;
  final String homeId;
  final String awayId;
  final String homeName;
  final String awayName;
  final String homeShort;
  final String awayShort;
  final bool involvesUser;
  final MatchResult result;
  final int homeRuns;
  final int homeWickets;
  final int awayRuns;
  final int awayWickets;
  final String summary;
  final bool userWon;
  final bool tied;
  final String venueName;

  String get scoreline =>
      '$homeShort $homeRuns/$homeWickets  vs  $awayShort $awayRuns/$awayWickets';
}

class LeagueSeasonOutcome {
  LeagueSeasonOutcome({
    required this.competition,
    required this.userTeam,
    required this.leagueMatches,
    required this.userLeagueMatches,
    required this.standings,
    required this.playoffMatches,
    required this.userPlayoffMatches,
    required this.userQualified,
    required this.userChampion,
    required this.eliminatedAt,
  });

  final LeagueCompetition competition;
  final CricketTeam userTeam;
  final List<LeagueMatchCard> leagueMatches;
  final List<LeagueMatchCard> userLeagueMatches;
  final List<LeagueStandingRow> standings;
  final List<LeagueMatchCard> playoffMatches;
  final List<LeagueMatchCard> userPlayoffMatches;
  final bool userQualified;
  final bool userChampion;
  final LeagueStage? eliminatedAt;

  bool get userEliminatedInLeague => !userQualified;

  @Deprecated('Use userTeam')
  CricketTeam get userFranchise => userTeam;
}

/// Builds the player's custom side that enters the league as a new team.
CricketTeam buildUserLeagueTeam(String rawName) {
  final cleaned = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
  final name = cleaned.isEmpty ? 'Playora XI' : cleaned;
  return CricketTeam(
    id: 'user_xi',
    name: name,
    shortName: shortNameForTeam(name),
    players: const [],
  );
}

String shortNameForTeam(String name) {
  final parts =
      name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.length >= 2) {
    final a = parts[0].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final b = parts[1].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (a.isNotEmpty && b.isNotEmpty) {
      return (a[0] + b[0]).toUpperCase();
    }
  }
  final compact = name.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (compact.length >= 3) return compact.substring(0, 3).toUpperCase();
  if (compact.isNotEmpty) return compact.toUpperCase();
  return 'YOU';
}

class LeagueEngine {
  LeagueEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  LeagueSeasonOutcome simulate({
    required LeagueCompetition competition,
    required CricketTeam userTeam,
    required Squad userSquad,
  }) {
    // User enters as an extra side against every franchise in the competition.
    final participants = <CricketTeam>[userTeam, ...competition.teams];
    final exclude = userSquad.players.map((p) => p.id).toSet();
    final squads = <String, Squad>{
      userTeam.id: userSquad,
      for (final team in competition.teams)
        team.id: DraftEngine.buildFranchiseXi(
          team,
          excludePlayerIds: exclude,
          maxOverseas: competition.maxOverseasPlayers,
        ),
    };

    final standings = {
      for (final team in participants)
        team.id: LeagueStandingRow(
          teamId: team.id,
          name: team.name,
          shortName: team.shortName,
          isUser: team.id == userTeam.id,
        ),
    };

    final leagueMatches = <LeagueMatchCard>[];
    final pairs = <(String, String)>[];
    for (var i = 0; i < participants.length; i++) {
      for (var j = i + 1; j < participants.length; j++) {
        pairs.add((participants[i].id, participants[j].id));
      }
    }
    pairs.shuffle(_random);

    var matchNo = 1;
    for (final pair in pairs) {
      final card = _playFixture(
        id: 'L$matchNo',
        stage: LeagueStage.league,
        homeId: pair.$1,
        awayId: pair.$2,
        participants: participants,
        squads: squads,
        userTeamId: userTeam.id,
      );
      leagueMatches.add(card);
      _applyResult(standings, card);
      matchNo += 1;
    }

    final table = standings.values.toList()
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        return b.nrr.compareTo(a.nrr);
      });

    final userQualified = table.take(4).any((row) => row.isUser);
    final userLeagueMatches =
        leagueMatches.where((m) => m.involvesUser).toList(growable: false);

    if (!userQualified) {
      return LeagueSeasonOutcome(
        competition: competition,
        userTeam: userTeam,
        leagueMatches: leagueMatches,
        userLeagueMatches: userLeagueMatches,
        standings: table,
        playoffMatches: const [],
        userPlayoffMatches: const [],
        userQualified: false,
        userChampion: false,
        eliminatedAt: LeagueStage.league,
      );
    }

    final top4 = table.take(4).toList();
    final first = top4[0].teamId;
    final second = top4[1].teamId;
    final third = top4[2].teamId;
    final fourth = top4[3].teamId;

    final playoffs = <LeagueMatchCard>[];

    final q1 = _playFixture(
      id: 'Q1',
      stage: LeagueStage.qualifier1,
      homeId: first,
      awayId: second,
      participants: participants,
      squads: squads,
      userTeamId: userTeam.id,
    );
    playoffs.add(q1);

    final elim = _playFixture(
      id: 'ELIM',
      stage: LeagueStage.eliminator,
      homeId: third,
      awayId: fourth,
      participants: participants,
      squads: squads,
      userTeamId: userTeam.id,
    );
    playoffs.add(elim);

    final q1Winner = _winnerId(q1);
    final q1Loser = _loserId(q1);
    final elimWinner = _winnerId(elim);

    if (elim.involvesUser && !elim.tied && !elim.userWon) {
      return LeagueSeasonOutcome(
        competition: competition,
        userTeam: userTeam,
        leagueMatches: leagueMatches,
        userLeagueMatches: userLeagueMatches,
        standings: table,
        playoffMatches: playoffs,
        userPlayoffMatches: playoffs.where((m) => m.involvesUser).toList(),
        userQualified: true,
        userChampion: false,
        eliminatedAt: LeagueStage.eliminator,
      );
    }

    // Rare tie handling: treat higher seed as advancing.
    final q2Home = q1Loser;
    final q2Away = elim.tied ? third : elimWinner;
    final resolvedQ2Away = q2Away == q2Home ? fourth : q2Away;

    final q2 = _playFixture(
      id: 'Q2',
      stage: LeagueStage.qualifier2,
      homeId: q2Home,
      awayId: resolvedQ2Away,
      participants: participants,
      squads: squads,
      userTeamId: userTeam.id,
    );
    playoffs.add(q2);

    if (q2.involvesUser && !q2.tied && !q2.userWon) {
      return LeagueSeasonOutcome(
        competition: competition,
        userTeam: userTeam,
        leagueMatches: leagueMatches,
        userLeagueMatches: userLeagueMatches,
        standings: table,
        playoffMatches: playoffs,
        userPlayoffMatches: playoffs.where((m) => m.involvesUser).toList(),
        userQualified: true,
        userChampion: false,
        eliminatedAt: LeagueStage.qualifier2,
      );
    }

    if (q1.involvesUser &&
        !q1.userWon &&
        !q1.tied &&
        !q2.involvesUser &&
        userTeam.id != _winnerId(q1) &&
        userTeam.id != _winnerId(q2)) {
      return LeagueSeasonOutcome(
        competition: competition,
        userTeam: userTeam,
        leagueMatches: leagueMatches,
        userLeagueMatches: userLeagueMatches,
        standings: table,
        playoffMatches: playoffs,
        userPlayoffMatches: playoffs.where((m) => m.involvesUser).toList(),
        userQualified: true,
        userChampion: false,
        eliminatedAt: LeagueStage.qualifier1,
      );
    }

    final finalHome = q1.tied ? first : q1Winner;
    final finalAway = q2.tied ? q2Home : _winnerId(q2);

    final finale = _playFixture(
      id: 'FINAL',
      stage: LeagueStage.finalMatch,
      homeId: finalHome,
      awayId: finalAway == finalHome ? second : finalAway,
      participants: participants,
      squads: squads,
      userTeamId: userTeam.id,
    );
    playoffs.add(finale);

    final userChampion = finale.involvesUser && (finale.userWon || finale.tied);
    LeagueStage? eliminatedAt;
    if (finale.involvesUser && !finale.userWon && !finale.tied) {
      eliminatedAt = LeagueStage.finalMatch;
    } else if (!finale.involvesUser) {
      eliminatedAt = LeagueStage.qualifier2;
    }

    return LeagueSeasonOutcome(
      competition: competition,
      userTeam: userTeam,
      leagueMatches: leagueMatches,
      userLeagueMatches: userLeagueMatches,
      standings: table,
      playoffMatches: playoffs,
      userPlayoffMatches: playoffs.where((m) => m.involvesUser).toList(),
      userQualified: true,
      userChampion: userChampion,
      eliminatedAt: userChampion ? null : eliminatedAt,
    );
  }

  String _winnerId(LeagueMatchCard match) {
    if (match.tied) return match.homeId;
    final homeWon = match.homeRuns > match.awayRuns;
    return homeWon ? match.homeId : match.awayId;
  }

  String _loserId(LeagueMatchCard match) {
    final winner = _winnerId(match);
    return winner == match.homeId ? match.awayId : match.homeId;
  }

  void _applyResult(
    Map<String, LeagueStandingRow> standings,
    LeagueMatchCard match,
  ) {
    final home = standings[match.homeId]!;
    final away = standings[match.awayId]!;
    home.played += 1;
    away.played += 1;

    final first = match.result.firstInnings;
    final second = match.result.secondInnings;
    final homeFirst = first.teamName == match.homeName;
    final homeInn = homeFirst ? first : second;
    final awayInn = homeFirst ? second : first;

    home.runsFor += homeInn.runs;
    home.oversFaced += _ballsToOvers(homeInn.balls);
    home.runsAgainst += awayInn.runs;
    home.oversBowled += _ballsToOvers(awayInn.balls);

    away.runsFor += awayInn.runs;
    away.oversFaced += _ballsToOvers(awayInn.balls);
    away.runsAgainst += homeInn.runs;
    away.oversBowled += _ballsToOvers(homeInn.balls);

    if (match.tied) {
      home.tied += 1;
      away.tied += 1;
    } else if (match.homeRuns > match.awayRuns) {
      home.won += 1;
      away.lost += 1;
    } else {
      away.won += 1;
      home.lost += 1;
    }
  }

  double _ballsToOvers(int balls) {
    if (balls <= 0) return 0.1;
    return balls / 6.0;
  }

  LeagueMatchCard _playFixture({
    required String id,
    required LeagueStage stage,
    required String homeId,
    required String awayId,
    required List<CricketTeam> participants,
    required Map<String, Squad> squads,
    required String userTeamId,
  }) {
    final home = participants.firstWhere((t) => t.id == homeId);
    final away = participants.firstWhere((t) => t.id == awayId);
    final involvesUser = homeId == userTeamId || awayId == userTeamId;

    // MatchEngine treats first squad arg as "user" for naming helpers.
    final userIsHome = homeId == userTeamId;
    final perspectiveHome = involvesUser ? userIsHome : true;
    final leftSquad = perspectiveHome ? squads[homeId]! : squads[awayId]!;
    final rightSquad = perspectiveHome ? squads[awayId]! : squads[homeId]!;
    final leftName = perspectiveHome ? home.name : away.name;
    final rightName = perspectiveHome ? away.name : home.name;

    final result = MatchEngine(random: Random(_random.nextInt(1 << 31))).play(
      format: CricketFormat.t20,
      userSquad: leftSquad,
      cpuSquad: rightSquad,
      userWantsToBat: _random.nextBool(),
      venue: pickVenue(_random),
      userTeamName: leftName,
      cpuTeamName: rightName,
    );

    final leftInn = result.userInnings;
    final rightInn = result.cpuInnings;
    final homeRuns = perspectiveHome ? leftInn.runs : rightInn.runs;
    final homeWkts = perspectiveHome ? leftInn.wickets : rightInn.wickets;
    final awayRuns = perspectiveHome ? rightInn.runs : leftInn.runs;
    final awayWkts = perspectiveHome ? rightInn.wickets : leftInn.wickets;

    final tied = homeRuns == awayRuns;
    final homeWon = homeRuns > awayRuns;
    final userWon = involvesUser &&
        ((userIsHome && homeWon) || (!userIsHome && !homeWon && !tied));

    String summary;
    if (tied) {
      summary = 'Scores level. Match tied.';
    } else if (homeWon) {
      summary = '${home.shortName} beat ${away.shortName}.';
    } else {
      summary = '${away.shortName} beat ${home.shortName}.';
    }

    // Prefer engine summary when the perspective side matches a named team.
    if (involvesUser) {
      summary = result.matchSummary
          .replaceAll(result.userTeamName, userIsHome ? home.shortName : away.shortName)
          .replaceAll(result.cpuTeamName, userIsHome ? away.shortName : home.shortName);
    }

    return LeagueMatchCard(
      id: id,
      stage: stage,
      homeId: homeId,
      awayId: awayId,
      homeName: home.name,
      awayName: away.name,
      homeShort: home.shortName,
      awayShort: away.shortName,
      involvesUser: involvesUser,
      result: result,
      homeRuns: homeRuns,
      homeWickets: homeWkts,
      awayRuns: awayRuns,
      awayWickets: awayWkts,
      summary: summary,
      userWon: userWon,
      tied: tied,
      venueName: result.venue.headline,
    );
  }
}
