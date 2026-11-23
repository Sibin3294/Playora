import 'package:flutter_test/flutter_test.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/game/hunt_archive.dart';

void main() {
  test('records wins, losses, and the best score', () {
    final archive = HuntArchive();
    final win = GuessEngine(secretNumber: 7)..submit(7);
    final loss = GuessEngine(secretNumber: 100);
    for (var value = 1; value <= 12; value++) {
      loss.submit(value);
    }

    archive.addFromEngine(win);
    archive.addFromEngine(loss);

    expect(archive.huntCount, 2);
    expect(archive.wins, 1);
    expect(archive.losses, 1);
    expect(archive.bestWin, 1);
    expect(archive.records.first.secretNumber, 100);
    expect(archive.records.last.won, isTrue);
  });

  test('clear empties the log', () {
    final archive = HuntArchive();
    archive.addFromEngine(GuessEngine(secretNumber: 3)..submit(3));
    archive.clear();
    expect(archive.records, isEmpty);
    expect(archive.bestWin, isNull);
  });
}
