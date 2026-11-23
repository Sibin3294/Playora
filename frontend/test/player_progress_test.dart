import 'package:flutter_test/flutter_test.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/game/player_progress.dart';

void main() {
  test('faster wins score more points', () {
    final fast = GuessEngine.fromLevel(HuntLevel.scout, secretNumber: 7)
      ..submit(7);
    final slow = GuessEngine.fromLevel(HuntLevel.scout, secretNumber: 7);
    for (var value = 1; value <= 6; value++) {
      slow.submit(value == 7 ? 8 : value);
    }
    slow.submit(7);

    expect(fast.pointsEarned, greaterThan(slow.pointsEarned));
    expect(slow.pointsEarned, greaterThan(0));
  });

  test('a loss awards no points', () {
    final engine = GuessEngine.fromLevel(HuntLevel.scout, secretNumber: 50);
    for (var value = 1; value <= 10; value++) {
      engine.submit(value);
    }
    expect(engine.isLost, isTrue);
    expect(engine.pointsEarned, 0);
  });

  test('points unlock the next hunt level', () {
    final progress = PlayerProgress();
    expect(progress.isUnlocked(HuntLevel.hunter), isFalse);

    final unlocked = progress.award(70);
    expect(progress.isUnlocked(HuntLevel.hunter), isTrue);
    expect(unlocked, contains(HuntLevel.hunter));
    expect(progress.select(HuntLevel.hunter), isTrue);
    expect(progress.select(HuntLevel.ranger), isFalse);
  });

  test('clearing the last level can award a one-time campaign bonus', () {
    final progress = PlayerProgress();
    expect(progress.markCampaignCleared(), isTrue);
    expect(progress.campaignCleared, isTrue);
    expect(progress.markCampaignCleared(), isFalse);
  });

  test('harder levels use a wider number range', () {
    expect(HuntLevel.scout.maxValue, 50);
    expect(HuntLevel.hunter.maxValue, 100);
    expect(HuntLevel.ranger.maxValue, 250);
    expect(HuntLevel.ace.maxValue, 500);
    expect(HuntLevel.phantom.maxValue, 1000);
    expect(HuntLevel.phantom.span, greaterThan(HuntLevel.scout.span));
  });
}
