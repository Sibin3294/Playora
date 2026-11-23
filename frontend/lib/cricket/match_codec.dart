import 'package:guess_game/cricket/match_engine.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/venues.dart';

Map<String, dynamic> squadToJson(Squad squad) => {
      'picks': [
        for (final pick in squad.picks)
          {
            'slotIndex': pick.slot.index,
            'fromTeamId': pick.fromTeamId,
            'player': {
              'id': pick.player.id,
              'name': pick.player.name,
              'teamId': pick.player.teamId,
              'roles': [for (final role in pick.player.roles) role.name],
              'batRating': pick.player.batRating,
              'bowlRating': pick.player.bowlRating,
              'fieldRating': pick.player.fieldRating,
              'isOverseas': pick.player.isOverseas,
            },
          },
      ],
    };

Squad squadFromJson(Map<String, dynamic> json) {
  final picksJson = json['picks'] as List<dynamic>? ?? const [];
  final picks = <DraftPick>[];
  for (final raw in picksJson) {
    final item = raw as Map<String, dynamic>;
    final slotIndex = item['slotIndex'] as int;
    final slot = t20Slots.firstWhere((s) => s.index == slotIndex);
    final playerJson = item['player'] as Map<String, dynamic>;
    final roles = (playerJson['roles'] as List<dynamic>? ?? const [])
        .map((name) => PlayerRole.values.firstWhere(
              (role) => role.name == name,
              orElse: () => PlayerRole.batter,
            ))
        .toList();
    picks.add(
      DraftPick(
        slot: slot,
        fromTeamId: item['fromTeamId'] as String? ?? '',
        player: CricketPlayer(
          id: playerJson['id'] as String,
          name: playerJson['name'] as String,
          teamId: playerJson['teamId'] as String,
          roles: roles,
          batRating: playerJson['batRating'] as int? ?? 70,
          bowlRating: playerJson['bowlRating'] as int? ?? 70,
          fieldRating: playerJson['fieldRating'] as int? ?? 70,
          isOverseas: playerJson['isOverseas'] as bool? ?? false,
        ),
      ),
    );
  }
  return Squad(picks: picks);
}

Map<String, dynamic> _playerCard(CricketPlayer player) => {
      'id': player.id,
      'name': player.name,
      'teamId': player.teamId,
      'roles': [for (final role in player.roles) role.name],
      'batRating': player.batRating,
      'bowlRating': player.bowlRating,
      'fieldRating': player.fieldRating,
      'isOverseas': player.isOverseas,
    };

CricketPlayer _readPlayer(Map<String, dynamic> json) {
  final roles = (json['roles'] as List<dynamic>? ?? const [])
      .map((name) => PlayerRole.values.firstWhere(
            (role) => role.name == name,
            orElse: () => PlayerRole.batter,
          ))
      .toList();
  return CricketPlayer(
    id: json['id'] as String,
    name: json['name'] as String,
    teamId: json['teamId'] as String,
    roles: roles,
    batRating: json['batRating'] as int? ?? 70,
    bowlRating: json['bowlRating'] as int? ?? 70,
    fieldRating: json['fieldRating'] as int? ?? 70,
    isOverseas: json['isOverseas'] as bool? ?? false,
  );
}

Map<String, dynamic> _batterToJson(BatterCard card) => {
      'player': _playerCard(card.player),
      'runs': card.runs,
      'balls': card.balls,
      'fours': card.fours,
      'sixes': card.sixes,
      'out': card.out,
      'dismissal': card.dismissal,
    };

BatterCard _batterFromJson(Map<String, dynamic> json) {
  final card = BatterCard(player: _readPlayer(json['player'] as Map<String, dynamic>));
  card.runs = json['runs'] as int? ?? 0;
  card.balls = json['balls'] as int? ?? 0;
  card.fours = json['fours'] as int? ?? 0;
  card.sixes = json['sixes'] as int? ?? 0;
  card.out = json['out'] as bool? ?? false;
  card.dismissal = json['dismissal'] as String? ?? '';
  return card;
}

Map<String, dynamic> _bowlerToJson(BowlerCard card) => {
      'player': _playerCard(card.player),
      'balls': card.balls,
      'runsConceded': card.runsConceded,
      'wickets': card.wickets,
      'maidens': card.maidens,
    };

BowlerCard _bowlerFromJson(Map<String, dynamic> json) {
  final card = BowlerCard(player: _readPlayer(json['player'] as Map<String, dynamic>));
  card.balls = json['balls'] as int? ?? 0;
  card.runsConceded = json['runsConceded'] as int? ?? 0;
  card.wickets = json['wickets'] as int? ?? 0;
  card.maidens = json['maidens'] as int? ?? 0;
  return card;
}

Map<String, dynamic> _inningsToJson(InningsCard card) => {
      'teamName': card.teamName,
      'extras': card.extras,
      'wickets': card.wickets,
      'balls': card.balls,
      'batters': [for (final batter in card.batters) _batterToJson(batter)],
      'bowlers': [for (final bowler in card.bowlers) _bowlerToJson(bowler)],
    };

InningsCard _inningsFromJson(Map<String, dynamic> json) {
  final card = InningsCard(
    teamName: json['teamName'] as String? ?? 'XI',
    batters: [
      for (final item in (json['batters'] as List<dynamic>? ?? const []))
        _batterFromJson(item as Map<String, dynamic>),
    ],
    bowlers: [
      for (final item in (json['bowlers'] as List<dynamic>? ?? const []))
        _bowlerFromJson(item as Map<String, dynamic>),
    ],
  );
  card.extras = json['extras'] as int? ?? 0;
  card.wickets = json['wickets'] as int? ?? 0;
  card.balls = json['balls'] as int? ?? 0;
  return card;
}

Map<String, dynamic> _overToJson(OverPulse over) => {
      'inningsNumber': over.inningsNumber,
      'overNumber': over.overNumber,
      'battingTeam': over.battingTeam,
      'bowlingTeam': over.bowlingTeam,
      'striker': over.striker,
      'bowler': over.bowler,
      'runsInOver': over.runsInOver,
      'wicketsInOver': over.wicketsInOver,
      'highlights': over.highlights,
      'totalRuns': over.totalRuns,
      'totalWickets': over.totalWickets,
      'oversLabel': over.oversLabel,
      'runRate': over.runRate,
      'target': over.target,
      'requiredRunRate': over.requiredRunRate,
    };

OverPulse _overFromJson(Map<String, dynamic> json) => OverPulse(
      inningsNumber: json['inningsNumber'] as int? ?? 1,
      overNumber: json['overNumber'] as int? ?? 1,
      battingTeam: json['battingTeam'] as String? ?? '',
      bowlingTeam: json['bowlingTeam'] as String? ?? '',
      striker: json['striker'] as String? ?? '',
      bowler: json['bowler'] as String? ?? '',
      runsInOver: json['runsInOver'] as int? ?? 0,
      wicketsInOver: json['wicketsInOver'] as int? ?? 0,
      highlights: [
        for (final item in (json['highlights'] as List<dynamic>? ?? const []))
          item as String,
      ],
      totalRuns: json['totalRuns'] as int? ?? 0,
      totalWickets: json['totalWickets'] as int? ?? 0,
      oversLabel: json['oversLabel'] as String? ?? '0.0',
      runRate: (json['runRate'] as num?)?.toDouble() ?? 0,
      target: json['target'] as int?,
      requiredRunRate: (json['requiredRunRate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _venueToJson(CricketVenue venue) => {
      'name': venue.name,
      'city': venue.city,
      'country': venue.country,
      'capacity': venue.capacity,
      'pitchReport': venue.pitchReport,
      'outfieldNote': venue.outfieldNote,
      'weather': venue.weather,
    };

CricketVenue _venueFromJson(Map<String, dynamic> json) => CricketVenue(
      name: json['name'] as String? ?? 'Stadium',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      pitchReport: json['pitchReport'] as String? ?? '',
      outfieldNote: json['outfieldNote'] as String? ?? '',
      weather: json['weather'] as String? ?? '',
    );

/// Host-perspective match payload (user = host, cpu = guest).
Map<String, dynamic> matchResultToJson(MatchResult result) => {
      'formatId': result.format.id,
      'userTeamName': result.userTeamName,
      'cpuTeamName': result.cpuTeamName,
      'userBattedFirst': result.userBattedFirst,
      'tossWinnerIsUser': result.tossWinnerIsUser,
      'electedToBat': result.electedToBat,
      'firstInnings': _inningsToJson(result.firstInnings),
      'secondInnings': _inningsToJson(result.secondInnings),
      'firstInningsOvers': [
        for (final over in result.firstInningsOvers) _overToJson(over),
      ],
      'secondInningsOvers': [
        for (final over in result.secondInningsOvers) _overToJson(over),
      ],
      'venue': _venueToJson(result.venue),
      'userSquad': squadToJson(result.userSquad),
      'cpuSquad': squadToJson(result.cpuSquad),
    };

MatchResult matchResultFromJson(Map<String, dynamic> json) {
  final formatId = json['formatId'] as String? ?? 't20';
  final format = CricketFormat.values.firstWhere(
    (item) => item.id == formatId,
    orElse: () => CricketFormat.t20,
  );
  return MatchResult(
    format: format,
    userTeamName: json['userTeamName'] as String? ?? 'HOST',
    cpuTeamName: json['cpuTeamName'] as String? ?? 'GUEST',
    userBattedFirst: json['userBattedFirst'] as bool? ?? true,
    tossWinnerIsUser: json['tossWinnerIsUser'] as bool? ?? true,
    electedToBat: json['electedToBat'] as bool? ?? true,
    firstInnings: _inningsFromJson(
      json['firstInnings'] as Map<String, dynamic>? ?? const {},
    ),
    secondInnings: _inningsFromJson(
      json['secondInnings'] as Map<String, dynamic>? ?? const {},
    ),
    firstInningsOvers: [
      for (final item in (json['firstInningsOvers'] as List<dynamic>? ?? const []))
        _overFromJson(item as Map<String, dynamic>),
    ],
    secondInningsOvers: [
      for (final item
          in (json['secondInningsOvers'] as List<dynamic>? ?? const []))
        _overFromJson(item as Map<String, dynamic>),
    ],
    venue: _venueFromJson(json['venue'] as Map<String, dynamic>? ?? const {}),
    userSquad: squadFromJson(
      json['userSquad'] as Map<String, dynamic>? ?? const {'picks': []},
    ),
    cpuSquad: squadFromJson(
      json['cpuSquad'] as Map<String, dynamic>? ?? const {'picks': []},
    ),
  );
}

/// Flips a host-perspective result so the guest sees themselves as "user".
MatchResult matchResultForGuest(MatchResult hostView) {
  return MatchResult(
    format: hostView.format,
    userTeamName: hostView.cpuTeamName,
    cpuTeamName: hostView.userTeamName,
    firstInnings: hostView.firstInnings,
    secondInnings: hostView.secondInnings,
    userBattedFirst: !hostView.userBattedFirst,
    tossWinnerIsUser: !hostView.tossWinnerIsUser,
    electedToBat: hostView.electedToBat,
    firstInningsOvers: hostView.firstInningsOvers,
    secondInningsOvers: hostView.secondInningsOvers,
    venue: hostView.venue,
    userSquad: hostView.cpuSquad,
    cpuSquad: hostView.userSquad,
  );
}
