import 'package:guess_game/cards/trump_models.dart';
import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/roster.dart';

/// Builds a Top Trumps deck from national cricket rosters.
List<TrumpCard> buildCricketTrumpDeck({int maxCards = 16}) {
  final all = <TrumpCard>[];
  for (final team in cricketTeams) {
    for (final player in team.players) {
      all.add(_cardFromPlayer(player, team.shortName));
    }
  }
  all.sort((a, b) => b.overall.compareTo(a.overall));
  if (all.length <= maxCards) return all;
  return all.take(maxCards).toList(growable: false);
}

TrumpCard _cardFromPlayer(CricketPlayer player, String teamShort) {
  final seed = _seed(player.id);
  final bat = player.batRating;
  final bowl = player.bowlRating;
  final field = player.fieldRating;

  final isBatter = bat >= bowl + 8;
  final isBowler = bowl >= bat + 8;
  final isKeeper = player.roles.contains(PlayerRole.wicketKeeper);

  final matches =
      (48 + (bat + bowl) * 0.22 + (seed % 37)).round().clamp(25, 180);

  final hundreds = isBowler
      ? (seed % 3)
      : ((bat - 55) * 0.35 + (seed % 6)).round().clamp(0, 45);
  final fifties = isBowler
      ? ((bat - 40) * 0.2 + (seed % 5)).round().clamp(0, 20)
      : ((bat - 45) * 0.7 + (seed % 12)).round().clamp(2, 90);
  final thirties = isBowler
      ? ((bat - 35) * 0.25 + (seed % 6)).round().clamp(0, 25)
      : ((bat - 40) * 0.55 + (seed % 10)).round().clamp(4, 70);
  final highScore = isBowler
      ? (18 + (bat * 0.35) + (seed % 22)).round().clamp(12, 75)
      : (55 + (bat * 0.55) + (seed % 35)).round().clamp(48, 175);

  final batAvgTenths = isBowler
      ? (80 + bat * 1.1 + (seed % 40)).round().clamp(60, 280)
      : (180 + bat * 2.4 + (seed % 55)).round().clamp(220, 620);
  final strikeRateTenths = isBowler
      ? (900 + bat * 2 + (seed % 80)).round().clamp(850, 1200)
      : (1100 + bat * 3.2 + (seed % 120)).round().clamp(1050, 1650);

  final runs = isBowler
      ? (120 + bat * 8 + (seed % 200)).round().clamp(80, 1800)
      : (800 + bat * 28 + (seed % 500)).round().clamp(600, 6500);
  final fours = isBowler
      ? (10 + bat ~/ 3 + (seed % 20)).clamp(5, 120)
      : (40 + bat + (seed % 60)).clamp(30, 520);
  final sixes = isBowler
      ? (2 + bat ~/ 8 + (seed % 10)).clamp(0, 60)
      : (15 + bat ~/ 2 + (seed % 35)).clamp(8, 280);
  final notOuts = isBowler
      ? (4 + (seed % 10)).clamp(2, 28)
      : (8 + bat ~/ 10 + (seed % 12)).clamp(5, 45);

  final wickets = isBatter
      ? ((bowl - 40) * 0.35 + (seed % 8)).round().clamp(0, 40)
      : ((bowl - 45) * 1.8 + (seed % 35)).round().clamp(15, 320);
  final fiveWicketHauls = isBatter
      ? (bowl > 70 ? (seed % 2) : 0)
      : ((bowl - 60) * 0.25 + (seed % 5)).round().clamp(0, 18);
  final maidens = isBatter
      ? (bowl > 65 ? 2 + (seed % 6) : seed % 4)
      : (8 + bowl ~/ 4 + (seed % 20)).clamp(5, 90);

  final bowlAvgTenths = isBatter
      ? (320 + (100 - bowl) * 1.2 + (seed % 40)).round().clamp(280, 520)
      : (180 + (100 - bowl) * 1.6 + (seed % 35)).round().clamp(140, 340);
  final economyTenths = isBatter
      ? (85 + (100 - bowl) * 0.35 + (seed % 18)).round().clamp(75, 120)
      : (55 + (100 - bowl) * 0.4 + (seed % 16)).round().clamp(48, 95);
  final bowlStrikeTenths = isBatter
      ? (380 + (100 - bowl) + (seed % 40)).round().clamp(320, 520)
      : (180 + (100 - bowl) * 1.4 + (seed % 35)).round().clamp(140, 320);

  final bestWickets = isBatter
      ? (bowl > 65 ? 2 + (seed % 2) : 1 + (seed % 2))
      : (3 + ((bowl - 70) / 8).floor() + (seed % 3)).clamp(2, 7).toInt();
  final bestRuns = isBatter
      ? (18 + (seed % 28))
      : (8 + ((100 - bowl) / 4).round() + (seed % 18)).clamp(4, 42).toInt();

  final catches = isKeeper
      ? (25 + field ~/ 2 + (seed % 30)).clamp(20, 180)
      : (12 + field ~/ 3 + (seed % 20)).clamp(8, 120);
  final stumpings = isKeeper
      ? (6 + field ~/ 8 + (seed % 12)).clamp(4, 55)
      : (seed % 3);

  return TrumpCard(
    id: player.id,
    name: player.name,
    teamShort: teamShort,
    bat: bat,
    bowl: bowl,
    field: field,
    matches: matches,
    runs: runs,
    hundreds: hundreds,
    fifties: fifties,
    thirties: thirties,
    highScore: highScore,
    batAvgTenths: batAvgTenths,
    strikeRateTenths: strikeRateTenths,
    fours: fours,
    sixes: sixes,
    notOuts: notOuts,
    wickets: wickets,
    fiveWicketHauls: fiveWicketHauls,
    maidens: maidens,
    bowlAvgTenths: bowlAvgTenths,
    economyTenths: economyTenths,
    bowlStrikeTenths: bowlStrikeTenths,
    bestFiguresWickets: bestWickets,
    bestFiguresRuns: bestRuns,
    catches: catches,
    stumpings: stumpings,
  );
}

int _seed(String id) {
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}
