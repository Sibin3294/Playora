import 'dart:math';

import 'package:guess_game/cards/cricket_trump_deck.dart';
import 'package:guess_game/cards/trump_models.dart';

/// Classic Top Trumps: play until one deck is empty.
class TrumpEngine {
  TrumpEngine({
    Random? random,
    int deckSize = 16,
    List<TrumpStat>? activeStats,
  })  : activeStats = List<TrumpStat>.unmodifiable(
          activeStats ?? TrumpStat.values,
        ),
        _random = random ?? Random() {
    final deck = List<TrumpCard>.from(buildCricketTrumpDeck(maxCards: deckSize))
      ..shuffle(_random);
    final mid = deck.length ~/ 2;
    userDeck.addAll(deck.sublist(0, mid));
    cpuDeck.addAll(deck.sublist(mid));
  }

  final Random _random;
  final List<TrumpStat> activeStats;
  final List<TrumpCard> userDeck = [];
  final List<TrumpCard> cpuDeck = [];
  final List<TrumpCard> pot = [];

  /// Winner of the last decisive round chooses next (user starts).
  bool userChooses = true;
  TrumpRoundResult? lastRound;
  bool get isOver => userDeck.isEmpty || cpuDeck.isEmpty;
  bool get userWon => cpuDeck.isEmpty && userDeck.isNotEmpty;

  TrumpCard? get userTop => userDeck.isEmpty ? null : userDeck.first;
  TrumpCard? get cpuTop => cpuDeck.isEmpty ? null : cpuDeck.first;

  TrumpStat cpuPickStat(TrumpCard card) {
    var best = activeStats.first;
    var bestStrength = -0x3fffffff;
    for (final stat in activeStats) {
      final strength = card.strengthOf(stat);
      if (strength > bestStrength) {
        bestStrength = strength;
        best = stat;
      }
    }
    return best;
  }

  TrumpRoundResult playRound(TrumpStat stat) {
    if (isOver) {
      throw StateError('Match already finished.');
    }
    final userCard = userDeck.removeAt(0);
    final cpuCard = cpuDeck.removeAt(0);
    final userValue = userCard.valueOf(stat);
    final cpuValue = cpuCard.valueOf(stat);

    late final TrumpRoundOutcome outcome;
    final userBeatsCpu = stat.higherWins
        ? userValue > cpuValue
        : userValue < cpuValue;
    final cpuBeatsUser = stat.higherWins
        ? cpuValue > userValue
        : cpuValue < userValue;

    if (userBeatsCpu) {
      outcome = TrumpRoundOutcome.userWin;
      userDeck.addAll([...pot, userCard, cpuCard]);
      pot.clear();
      userChooses = true;
    } else if (cpuBeatsUser) {
      outcome = TrumpRoundOutcome.cpuWin;
      cpuDeck.addAll([...pot, cpuCard, userCard]);
      pot.clear();
      userChooses = false;
    } else {
      outcome = TrumpRoundOutcome.tie;
      pot.addAll([userCard, cpuCard]);
    }

    final result = TrumpRoundResult(
      stat: stat,
      userCard: userCard,
      cpuCard: cpuCard,
      outcome: outcome,
    );
    lastRound = result;
    return result;
  }
}
