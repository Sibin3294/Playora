import 'package:flutter_test/flutter_test.dart';
import 'package:guess_game/game/guess_engine.dart';

void main() {
  test('a correct guess wins the hunt', () {
    final engine = GuessEngine(secretNumber: 42);
    final result = engine.submit(42);

    expect(result.isError, isFalse);
    expect(result.attempt!.isCorrect, isTrue);
    expect(engine.isWon, isTrue);
    expect(engine.isLost, isFalse);
  });

  test('high and low guesses tighten the window', () {
    final engine = GuessEngine(secretNumber: 40);

    engine.submit(20);
    expect(engine.guesses.last.direction, GuessDirection.tooLow);
    expect(engine.lowBound, 21);

    engine.submit(80);
    expect(engine.guesses.last.direction, GuessDirection.tooHigh);
    expect(engine.highBound, 79);
  });

  test('hints unlock after three, six, and nine misses', () {
    final engine = GuessEngine(secretNumber: 55);

    engine.submit(1);
    engine.submit(2);
    expect(engine.unlockedHints, isEmpty);

    engine.submit(3);
    expect(engine.unlockedHints, hasLength(1));
    expect(engine.unlockedHints.first, contains('odd'));

    engine.submit(4);
    engine.submit(5);
    engine.submit(6);
    expect(engine.unlockedHints, hasLength(2));
    expect(engine.unlockedHints.last, contains('between'));

    engine.submit(7);
    engine.submit(8);
    engine.submit(9);
    expect(engine.unlockedHints, hasLength(3));
    expect(engine.unlockedHints.last, contains('starts with 5'));
  });

  test('twelve misses lose the hunt', () {
    final engine = GuessEngine(secretNumber: 100);
    for (var value = 1; value <= 12; value++) {
      engine.submit(value);
    }

    expect(engine.isLost, isTrue);
    expect(engine.attemptsLeft, 0);
    expect(engine.submit(13).isError, isTrue);
  });

  test('rejects duplicates and out of range guesses', () {
    final engine = GuessEngine(secretNumber: 50);

    expect(engine.submit(0).error, isNotNull);
    expect(engine.submit(101).error, isNotNull);
    engine.submit(10);
    expect(engine.submit(10).error, isNotNull);
  });
}
