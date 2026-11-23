import 'dart:math';

import 'package:guess_game/game/hunt_level.dart';

enum GuessDirection { tooLow, tooHigh, correct }

enum Heat { ice, chilly, warm, hot, scorching }

class GuessAttempt {
  const GuessAttempt({
    required this.value,
    required this.direction,
    required this.heat,
  });

  final int value;
  final GuessDirection direction;
  final Heat heat;

  bool get isCorrect => direction == GuessDirection.correct;
}

class SubmitResult {
  const SubmitResult._({
    this.error,
    this.attempt,
  });

  const SubmitResult.error(String message) : this._(error: message);

  const SubmitResult.ok(GuessAttempt attempt) : this._(attempt: attempt);

  final String? error;
  final GuessAttempt? attempt;

  bool get isError => error != null;
}

class GuessEngine {
  GuessEngine({
    int? secretNumber,
    this.minValue = 1,
    this.maxValue = 100,
    this.maxAttempts = 12,
    this.level,
    this.providedHints,
    this.closestOverride,
    Random? random,
  })  : secretNumber = secretNumber ??
            minValue + (random ?? Random()).nextInt(maxValue - minValue + 1),
        lowBound = minValue,
        highBound = maxValue;

  factory GuessEngine.fromLevel(
    HuntLevel level, {
    int? secretNumber,
    Random? random,
  }) {
    return GuessEngine(
      secretNumber: secretNumber,
      minValue: level.minValue,
      maxValue: level.maxValue,
      maxAttempts: level.maxAttempts,
      level: level,
      random: random,
    );
  }

  final HuntLevel? level;
  final int secretNumber;
  final int minValue;
  final int maxValue;
  final int maxAttempts;
  final List<String>? providedHints;
  final int? closestOverride;
  final List<GuessAttempt> guesses = [];

  int lowBound;
  int highBound;

  int get attemptsUsed => guesses.length;
  int get attemptsLeft => maxAttempts - attemptsUsed;
  bool get isWon => guesses.any((guess) => guess.isCorrect);
  bool get isLost => !isWon && attemptsLeft <= 0;
  bool get isOver => isWon || isLost;
  int get failedGuesses => guesses.where((guess) => !guess.isCorrect).length;
  int get maxDigits => maxValue.toString().length;

  int get pointsEarned {
    if (!isWon) return 0;
    if (level != null) {
      return level!.scoreFor(
        won: true,
        attemptsUsed: attemptsUsed,
        attemptsCap: maxAttempts,
      );
    }
    final leftover = maxAttempts - attemptsUsed + 1;
    var points = leftover * 10.0;
    if (attemptsUsed == 1) {
      points += 50;
    } else if (attemptsUsed <= 3) {
      points += 20;
    }
    return points.round();
  }

  List<String> get unlockedHints => providedHints ?? _computedHints;

  List<String> get _computedHints {
    if (failedGuesses < 3) return const [];
    final hints = <String>[
      secretNumber.isEven ? 'The number is even.' : 'The number is odd.',
    ];
    if (failedGuesses >= 6) {
      final window = max(8, (maxValue - minValue) ~/ 8);
      final start = (secretNumber - window).clamp(lowBound, highBound);
      final end = (secretNumber + window).clamp(lowBound, highBound);
      hints.add('It sits between $start and $end.');
    }
    if (failedGuesses >= 9) {
      if (secretNumber < 10) {
        hints.add('It is a single-digit number.');
      } else if (secretNumber < 100) {
        hints.add('It starts with ${secretNumber ~/ 10}.');
      } else {
        hints.add('It starts with ${secretNumber.toString()[0]}.');
      }
    }
    return hints;
  }

  bool get justUnlockedHint {
    return failedGuesses == 3 || failedGuesses == 6 || failedGuesses == 9;
  }

  SubmitResult submit(int guess) {
    if (isOver) {
      return const SubmitResult.error('This hunt is over. Play again!');
    }
    if (guess < minValue || guess > maxValue) {
      return SubmitResult.error('Pick a number from $minValue to $maxValue.');
    }
    if (guesses.any((item) => item.value == guess)) {
      return const SubmitResult.error('You already tried that number.');
    }

    final direction = guess == secretNumber
        ? GuessDirection.correct
        : (guess < secretNumber
            ? GuessDirection.tooLow
            : GuessDirection.tooHigh);

    if (direction == GuessDirection.tooLow) {
      lowBound = max(lowBound, guess + 1);
    } else if (direction == GuessDirection.tooHigh) {
      highBound = min(highBound, guess - 1);
    }

    final attempt = GuessAttempt(
      value: guess,
      direction: direction,
      heat: _heatFor(guess),
    );
    guesses.add(attempt);
    return SubmitResult.ok(attempt);
  }

  int get closestDistance {
    if (closestOverride != null) return closestOverride!;
    if (guesses.isEmpty) return maxValue;
    return guesses
        .map((guess) => (guess.value - secretNumber).abs())
        .reduce(min);
  }

  Heat _heatFor(int guess) {
    final distance = (guess - secretNumber).abs();
    final span = max(1, maxValue - minValue);
    final pct = distance / span;
    if (distance <= 2 || pct <= 0.02) return Heat.scorching;
    if (pct <= 0.06) return Heat.hot;
    if (pct <= 0.12) return Heat.warm;
    if (pct <= 0.25) return Heat.chilly;
    return Heat.ice;
  }
}

extension GuessDirectionCopy on GuessDirection {
  String get hudLabel {
    switch (this) {
      case GuessDirection.tooLow:
        return 'TOO LOW';
      case GuessDirection.tooHigh:
        return 'TOO HIGH';
      case GuessDirection.correct:
        return 'LOCKED IN';
    }
  }

  String get arrow => this == GuessDirection.tooLow
      ? '↑'
      : this == GuessDirection.tooHigh
          ? '↓'
          : '★';
}

extension HeatCopy on Heat {
  String get label {
    switch (this) {
      case Heat.ice:
        return 'ICE COLD';
      case Heat.chilly:
        return 'CHILLY';
      case Heat.warm:
        return 'WARM';
      case Heat.hot:
        return 'HOT';
      case Heat.scorching:
        return 'ON FIRE';
    }
  }
}
