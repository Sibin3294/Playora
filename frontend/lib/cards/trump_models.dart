enum TrumpStat {
  // Level-1 starters
  bat('BAT', 'Batting', higherWins: true),
  bowl('BOWL', 'Bowling', higherWins: true),
  field('FIELD', 'Fielding', higherWins: true),
  overall('OVR', 'Overall', higherWins: true),

  // Career batting
  matches('MAT', 'Matches', higherWins: true),
  runs('RUNS', 'Runs', higherWins: true),
  hundreds('100s', 'Hundreds', higherWins: true),
  fifties('50s', 'Fifties', higherWins: true),
  thirties('30s', 'Thirties', higherWins: true),
  highScore('HS', 'High score', higherWins: true),
  batAvg('BAVG', 'Bat average', higherWins: true),
  strikeRate('SR', 'Strike rate', higherWins: true),
  fours('4s', 'Fours', higherWins: true),
  sixes('6s', 'Sixes', higherWins: true),
  notOuts('NO', 'Not outs', higherWins: true),

  // Career bowling / fielding
  wickets('WKTS', 'Wickets', higherWins: true),
  fiveWickets('5WI', '5+ wicket hauls', higherWins: true),
  maidens('MDNS', 'Maidens', higherWins: true),
  bowlAvg('BOAVG', 'Bowl average', higherWins: false),
  economy('ECON', 'Economy', higherWins: false),
  bowlStrike('BSR', 'Bowl strike rate', higherWins: false),
  bestFigures('BB', 'Best figures', higherWins: true),
  catches('CT', 'Catches', higherWins: true),
  stumpings('ST', 'Stumpings', higherWins: true);

  const TrumpStat(
    this.shortLabel,
    this.label, {
    required this.higherWins,
  });

  final String shortLabel;
  final String label;

  /// When false, the lower value wins (economy, averages, bowl SR).
  final bool higherWins;

  static TrumpStat? tryParse(String name) {
    for (final stat in TrumpStat.values) {
      if (stat.name == name) return stat;
    }
    return null;
  }
}

class TrumpCard {
  const TrumpCard({
    required this.id,
    required this.name,
    required this.teamShort,
    required this.bat,
    required this.bowl,
    required this.field,
    required this.matches,
    required this.runs,
    required this.hundreds,
    required this.fifties,
    required this.thirties,
    required this.highScore,
    required this.batAvgTenths,
    required this.strikeRateTenths,
    required this.fours,
    required this.sixes,
    required this.notOuts,
    required this.wickets,
    required this.fiveWicketHauls,
    required this.maidens,
    required this.bowlAvgTenths,
    required this.economyTenths,
    required this.bowlStrikeTenths,
    required this.bestFiguresWickets,
    required this.bestFiguresRuns,
    required this.catches,
    required this.stumpings,
  });

  final String id;
  final String name;
  final String teamShort;
  final int bat;
  final int bowl;
  final int field;
  final int matches;
  final int runs;
  final int hundreds;
  final int fifties;
  final int thirties;
  final int highScore;
  final int batAvgTenths;
  final int strikeRateTenths;
  final int fours;
  final int sixes;
  final int notOuts;
  final int wickets;
  final int fiveWicketHauls;
  final int maidens;
  final int bowlAvgTenths;
  final int economyTenths;
  final int bowlStrikeTenths;
  final int bestFiguresWickets;
  final int bestFiguresRuns;
  final int catches;
  final int stumpings;

  int get overall =>
      ((bat * 0.45) + (bowl * 0.35) + (field * 0.2)).round();

  int get bestFiguresScore =>
      bestFiguresWickets * 1000 + (100 - bestFiguresRuns.clamp(0, 99));

  int valueOf(TrumpStat stat) {
    switch (stat) {
      case TrumpStat.bat:
        return bat;
      case TrumpStat.bowl:
        return bowl;
      case TrumpStat.field:
        return field;
      case TrumpStat.overall:
        return overall;
      case TrumpStat.matches:
        return matches;
      case TrumpStat.runs:
        return runs;
      case TrumpStat.hundreds:
        return hundreds;
      case TrumpStat.fifties:
        return fifties;
      case TrumpStat.thirties:
        return thirties;
      case TrumpStat.highScore:
        return highScore;
      case TrumpStat.batAvg:
        return batAvgTenths;
      case TrumpStat.strikeRate:
        return strikeRateTenths;
      case TrumpStat.fours:
        return fours;
      case TrumpStat.sixes:
        return sixes;
      case TrumpStat.notOuts:
        return notOuts;
      case TrumpStat.wickets:
        return wickets;
      case TrumpStat.fiveWickets:
        return fiveWicketHauls;
      case TrumpStat.maidens:
        return maidens;
      case TrumpStat.bowlAvg:
        return bowlAvgTenths;
      case TrumpStat.economy:
        return economyTenths;
      case TrumpStat.bowlStrike:
        return bowlStrikeTenths;
      case TrumpStat.bestFigures:
        return bestFiguresScore;
      case TrumpStat.catches:
        return catches;
      case TrumpStat.stumpings:
        return stumpings;
    }
  }

  String displayOf(TrumpStat stat) {
    switch (stat) {
      case TrumpStat.batAvg:
        return (batAvgTenths / 10).toStringAsFixed(1);
      case TrumpStat.bowlAvg:
        return (bowlAvgTenths / 10).toStringAsFixed(1);
      case TrumpStat.economy:
        return (economyTenths / 10).toStringAsFixed(1);
      case TrumpStat.strikeRate:
        return (strikeRateTenths / 10).toStringAsFixed(1);
      case TrumpStat.bowlStrike:
        return (bowlStrikeTenths / 10).toStringAsFixed(1);
      case TrumpStat.bestFigures:
        return '$bestFiguresWickets/$bestFiguresRuns';
      default:
        return '${valueOf(stat)}';
    }
  }

  int strengthOf(TrumpStat stat) {
    final value = valueOf(stat);
    return stat.higherWins ? value : -value;
  }
}

enum TrumpRoundOutcome { userWin, cpuWin, tie }

class TrumpRoundResult {
  const TrumpRoundResult({
    required this.stat,
    required this.userCard,
    required this.cpuCard,
    required this.outcome,
  });

  final TrumpStat stat;
  final TrumpCard userCard;
  final TrumpCard cpuCard;
  final TrumpRoundOutcome outcome;
}
