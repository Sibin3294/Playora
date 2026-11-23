import 'dart:math';

import 'package:guess_game/cricket/models.dart';
import 'package:guess_game/cricket/venues.dart';

class BatterCard {
  BatterCard({required this.player});

  final CricketPlayer player;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  bool out = false;
  String dismissal = '';

  int get fantasyPoints {
    var points = runs;
    points += fours;
    points += sixes * 2;
    if (runs >= 100) {
      points += 16;
    } else if (runs >= 50) {
      points += 8;
    }
    if (balls >= 10 && runs == 0) points -= 5;
    return points;
  }
}

class BowlerCard {
  BowlerCard({required this.player});

  final CricketPlayer player;
  int balls = 0;
  int runsConceded = 0;
  int wickets = 0;
  int maidens = 0;
  int _runsThisOver = 0;

  double get overs => balls / 6.0;

  int get fantasyPoints {
    var points = wickets * 25;
    if (wickets >= 3) points += 8;
    if (wickets >= 5) points += 16;
    points += maidens * 12;
    final economy = balls == 0 ? 0.0 : runsConceded * 6 / balls;
    if (balls >= 12) {
      if (economy < 6) {
        points += 6;
      } else if (economy > 10) {
        points -= 4;
      }
    }
    return points;
  }

  void startOver() => _runsThisOver = 0;

  void addRuns(int runs) {
    runsConceded += runs;
    _runsThisOver += runs;
    balls += 1;
  }

  void addWicket() {
    wickets += 1;
    balls += 1;
  }

  void endOver() {
    if (_runsThisOver == 0 && balls % 6 == 0) {
      maidens += 1;
    }
  }
}

class InningsCard {
  InningsCard({
    required this.teamName,
    required this.batters,
    required this.bowlers,
  });

  final String teamName;
  final List<BatterCard> batters;
  final List<BowlerCard> bowlers;
  int extras = 0;
  int wickets = 0;
  int balls = 0;

  int get runs =>
      batters.fold<int>(0, (sum, batter) => sum + batter.runs) + extras;

  String get oversLabel {
    final whole = balls ~/ 6;
    final rem = balls % 6;
    return '$whole.$rem';
  }

  int get battingFantasy =>
      batters.fold<int>(0, (sum, batter) => sum + batter.fantasyPoints);

  int get bowlingFantasy =>
      bowlers.fold<int>(0, (sum, bowler) => sum + bowler.fantasyPoints);

  int get totalFantasy => battingFantasy + bowlingFantasy;
}

enum MatchPhase {
  toss,
  firstInningsLive,
  inningsBreak,
  secondInningsLive,
  finished,
}

class OverPulse {
  const OverPulse({
    required this.inningsNumber,
    required this.overNumber,
    required this.battingTeam,
    required this.bowlingTeam,
    required this.striker,
    required this.bowler,
    required this.runsInOver,
    required this.wicketsInOver,
    required this.highlights,
    required this.totalRuns,
    required this.totalWickets,
    required this.oversLabel,
    required this.runRate,
    this.target,
    this.requiredRunRate,
  });

  final int inningsNumber;
  final int overNumber;
  final String battingTeam;
  final String bowlingTeam;
  final String striker;
  final String bowler;
  final int runsInOver;
  final int wicketsInOver;
  final List<String> highlights;
  final int totalRuns;
  final int totalWickets;
  final String oversLabel;
  final double runRate;
  final int? target;
  final double? requiredRunRate;

  String get scoreline => '$totalRuns/$totalWickets ($oversLabel ov)';
}

class MatchResult {
  MatchResult({
    required this.format,
    required this.userTeamName,
    required this.cpuTeamName,
    required this.firstInnings,
    required this.secondInnings,
    required this.userBattedFirst,
    required this.tossWinnerIsUser,
    required this.electedToBat,
    required this.firstInningsOvers,
    required this.secondInningsOvers,
    required this.venue,
    required this.userSquad,
    required this.cpuSquad,
  });

  final CricketFormat format;
  final String userTeamName;
  final String cpuTeamName;
  final InningsCard firstInnings;
  final InningsCard secondInnings;
  final bool userBattedFirst;
  final bool tossWinnerIsUser;
  final bool electedToBat;
  final List<OverPulse> firstInningsOvers;
  final List<OverPulse> secondInningsOvers;
  final CricketVenue venue;
  final Squad userSquad;
  final Squad cpuSquad;

  InningsCard get userInnings =>
      userBattedFirst ? firstInnings : secondInnings;

  InningsCard get cpuInnings =>
      userBattedFirst ? secondInnings : firstInnings;

  int get userPoints => userInnings.totalFantasy;
  int get cpuPoints => cpuInnings.totalFantasy;

  bool get userWonOnScore => userInnings.runs > cpuInnings.runs;
  bool get tieOnScore => userInnings.runs == cpuInnings.runs;
  bool get userWonOnPoints => userPoints > cpuPoints;

  String get tossSummary {
    final winner = tossWinnerIsUser ? userTeamName : cpuTeamName;
    final choice = electedToBat ? 'bat' : 'bowl';
    return '$winner won the toss and elected to $choice first.';
  }

  String get matchSummary {
    if (tieOnScore) {
      return 'Scores level. The contest ends in a tie.';
    }
    if (userWonOnScore) {
      if (userBattedFirst) {
        return '$userTeamName defended the total and won by ${userInnings.runs - cpuInnings.runs} runs.';
      }
      final wicketsLeft = 10 - userInnings.wickets;
      return '$userTeamName chased it down and won by $wicketsLeft wicket${wicketsLeft == 1 ? '' : 's'}.';
    }
    if (!userBattedFirst) {
      return '$cpuTeamName defended the total and won by ${cpuInnings.runs - userInnings.runs} runs.';
    }
    final wicketsLeft = 10 - cpuInnings.wickets;
    return '$cpuTeamName chased it down and won by $wicketsLeft wicket${wicketsLeft == 1 ? '' : 's'}.';
  }
}

class MatchEngine {
  MatchEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  MatchResult play({
    required CricketFormat format,
    required Squad userSquad,
    required Squad cpuSquad,
    bool userWantsToBat = true,
    bool? tossWinnerIsUser,
    bool? electedToBat,
    CricketVenue? venue,
    String userTeamName = 'YOUR XI',
    String cpuTeamName = 'RIVAL XI',
  }) {
    final ground = venue ?? pickVenue(_random);
    final tossWonByUser = tossWinnerIsUser ?? _random.nextBool();
    final bool choseBat;
    if (electedToBat != null) {
      choseBat = electedToBat;
    } else if (tossWonByUser) {
      choseBat = userWantsToBat;
    } else {
      // Rival captain chooses after winning the toss.
      choseBat = _random.nextBool();
    }
    final userBatsFirst = tossWonByUser ? choseBat : !choseBat;

    final firstSquad = userBatsFirst ? userSquad : cpuSquad;
    final secondSquad = userBatsFirst ? cpuSquad : userSquad;
    final firstName = userBatsFirst ? userTeamName : cpuTeamName;
    final secondName = userBatsFirst ? cpuTeamName : userTeamName;
    final firstBowlName = userBatsFirst ? cpuTeamName : userTeamName;
    final secondBowlName = userBatsFirst ? userTeamName : cpuTeamName;

    final firstOvers = <OverPulse>[];
    final first = _playInnings(
      format: format,
      batting: firstSquad,
      bowling: secondSquad,
      battingTeam: firstName,
      bowlingTeam: firstBowlName,
      inningsNumber: 1,
      oversOut: firstOvers,
    );

    final secondOvers = <OverPulse>[];
    final second = _playInnings(
      format: format,
      batting: secondSquad,
      bowling: firstSquad,
      battingTeam: secondName,
      bowlingTeam: secondBowlName,
      inningsNumber: 2,
      target: first.runs + 1,
      oversOut: secondOvers,
    );

    return MatchResult(
      format: format,
      userTeamName: userTeamName,
      cpuTeamName: cpuTeamName,
      firstInnings: first,
      secondInnings: second,
      userBattedFirst: userBatsFirst,
      tossWinnerIsUser: tossWonByUser,
      electedToBat: choseBat,
      firstInningsOvers: firstOvers,
      secondInningsOvers: secondOvers,
      venue: ground,
      userSquad: userSquad,
      cpuSquad: cpuSquad,
    );
  }

  InningsCard _playInnings({
    required CricketFormat format,
    required Squad batting,
    required Squad bowling,
    required String battingTeam,
    required String bowlingTeam,
    required int inningsNumber,
    required List<OverPulse> oversOut,
    int? target,
  }) {
    final batters =
        batting.players.map((player) => BatterCard(player: player)).toList();
    final bowlerPool = bowling.players
        .where((player) => player.isBowlerType)
        .map((player) => BowlerCard(player: player))
        .toList();
    if (bowlerPool.length < 3) {
      bowlerPool
        ..clear()
        ..addAll(
          bowling.players.map((player) => BowlerCard(player: player)),
        );
    }

    final card = InningsCard(
      teamName: battingTeam,
      batters: batters,
      bowlers: bowlerPool,
    );

    var strikerIndex = 0;
    var nonStrikerIndex = 1;
    var nextBatter = 2;
    var bowlerIndex = 0;
    var overNumber = 0;
    final maxBalls = format.overs * 6;

    while (card.balls < maxBalls &&
        card.wickets < 10 &&
        nextBatter <= batters.length) {
      if (target != null && card.runs >= target) break;

      final bowler = bowlerPool[bowlerIndex % bowlerPool.length];
      bowler.startOver();
      var runsInOver = 0;
      var wicketsInOver = 0;
      final highlights = <String>[];
      var legalBalls = 0;

      while (legalBalls < 6) {
        if (card.balls >= maxBalls || card.wickets >= 10) break;
        if (target != null && card.runs >= target) break;
        if (strikerIndex >= batters.length) break;

        final striker = batters[strikerIndex];
        final outcome = _ballOutcome(striker.player, bowler.player);

        if (outcome.isWicket) {
          striker.balls += 1;
          striker.out = true;
          striker.dismissal = 'b ${bowler.player.name}';
          bowler.addWicket();
          card.wickets += 1;
          card.balls += 1;
          legalBalls += 1;
          wicketsInOver += 1;
          highlights.add('WICKET! ${striker.player.name} cleaned up');
          if (nextBatter >= batters.length) {
            break;
          }
          strikerIndex = nextBatter;
          nextBatter += 1;
          continue;
        }

        if (outcome.isWide) {
          card.extras += outcome.runs;
          bowler.runsConceded += outcome.runs;
          runsInOver += outcome.runs;
          highlights.add('WIDE');
          continue;
        }

        striker.runs += outcome.runs;
        striker.balls += 1;
        if (outcome.runs == 4) {
          striker.fours += 1;
          highlights.add('FOUR!');
        }
        if (outcome.runs == 6) {
          striker.sixes += 1;
          highlights.add('SIX!');
        }
        bowler.addRuns(outcome.runs);
        card.balls += 1;
        legalBalls += 1;
        runsInOver += outcome.runs;

        if (outcome.runs % 2 == 1) {
          final swap = strikerIndex;
          strikerIndex = nonStrikerIndex;
          nonStrikerIndex = swap;
        }
      }

      bowler.endOver();
      overNumber += 1;

      final runRate = card.balls == 0 ? 0.0 : card.runs * 6 / card.balls;
      double? required;
      if (target != null) {
        final ballsLeft = maxBalls - card.balls;
        final runsNeeded = target - card.runs;
        required = ballsLeft <= 0 ? 0 : runsNeeded * 6 / ballsLeft;
      }

      oversOut.add(
        OverPulse(
          inningsNumber: inningsNumber,
          overNumber: overNumber,
          battingTeam: battingTeam,
          bowlingTeam: bowlingTeam,
          striker: batters[strikerIndex.clamp(0, batters.length - 1)].player.name,
          bowler: bowler.player.name,
          runsInOver: runsInOver,
          wicketsInOver: wicketsInOver,
          highlights: highlights.isEmpty ? const ['Maiden pressure'] : highlights,
          totalRuns: card.runs,
          totalWickets: card.wickets,
          oversLabel: card.oversLabel,
          runRate: runRate,
          target: target,
          requiredRunRate: required,
        ),
      );

      final swap = strikerIndex;
      strikerIndex = nonStrikerIndex;
      nonStrikerIndex = swap;
      bowlerIndex += 1;

      if (card.wickets >= 10 || nextBatter > batters.length) break;
      if (target != null && card.runs >= target) break;
    }

    return card;
  }

  _BallOutcome _ballOutcome(CricketPlayer batter, CricketPlayer bowler) {
    final gap = batter.batRating - bowler.bowlRating;
    final roll = _random.nextDouble();

    final wicketChance = (0.045 - gap * 0.00045).clamp(0.02, 0.12);
    if (roll < wicketChance) {
      return const _BallOutcome.wicket();
    }

    final shotRoll = _random.nextDouble();
    final power = ((batter.batRating - 50) / 50).clamp(0.0, 1.0);
    if (shotRoll < 0.04 + power * 0.05) return const _BallOutcome.runs(6);
    if (shotRoll < 0.14 + power * 0.10) return const _BallOutcome.runs(4);
    if (shotRoll < 0.28) return const _BallOutcome.runs(3);
    if (shotRoll < 0.48) return const _BallOutcome.runs(2);
    if (shotRoll < 0.72) return const _BallOutcome.runs(1);
    if (shotRoll < 0.78) return const _BallOutcome.wide();
    return const _BallOutcome.runs(0);
  }
}

class _BallOutcome {
  const _BallOutcome.runs(this.runs)
      : isWicket = false,
        isWide = false,
        isNoBall = false;

  const _BallOutcome.wicket()
      : runs = 0,
        isWicket = true,
        isWide = false,
        isNoBall = false;

  const _BallOutcome.wide()
      : runs = 1,
        isWicket = false,
        isWide = true,
        isNoBall = false;

  final int runs;
  final bool isWicket;
  final bool isWide;
  final bool isNoBall;
}
