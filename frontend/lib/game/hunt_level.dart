import 'package:flutter/material.dart';
import 'package:guess_game/theme/game_theme.dart';

class HuntLevel {
  const HuntLevel({
    required this.id,
    required this.name,
    required this.blurb,
    required this.minValue,
    required this.maxValue,
    required this.maxAttempts,
    required this.pointsToUnlock,
    required this.multiplier,
    required this.accent,
  });

  final int id;
  final String name;
  final String blurb;
  final int minValue;
  final int maxValue;
  final int maxAttempts;
  final int pointsToUnlock;
  final double multiplier;
  final Color accent;

  String get rangeLabel => '$minValue–$maxValue';

  int get span => maxValue - minValue + 1;

  int scoreFor({
    required bool won,
    required int attemptsUsed,
    int? attemptsCap,
  }) {
    if (!won) return 0;
    final leftover = (attemptsCap ?? maxAttempts) - attemptsUsed + 1;
    var points = leftover * 10 * multiplier;
    if (attemptsUsed == 1) {
      points += 50 * multiplier;
    } else if (attemptsUsed <= 3) {
      points += 20 * multiplier;
    }
    return points.round();
  }

  static const scout = HuntLevel(
    id: 1,
    name: 'SCOUT',
    blurb: 'Warm up on a tight grid.',
    minValue: 1,
    maxValue: 50,
    maxAttempts: 10,
    pointsToUnlock: 0,
    multiplier: 1,
    accent: GameColors.cyan,
  );

  static const hunter = HuntLevel(
    id: 2,
    name: 'HUNTER',
    blurb: 'Classic hunt. Bigger field.',
    minValue: 1,
    maxValue: 100,
    maxAttempts: 12,
    pointsToUnlock: 70,
    multiplier: 1.25,
    accent: GameColors.lime,
  );

  static const ranger = HuntLevel(
    id: 3,
    name: 'RANGER',
    blurb: 'The number can hide much farther.',
    minValue: 1,
    maxValue: 250,
    maxAttempts: 12,
    pointsToUnlock: 180,
    multiplier: 1.5,
    accent: GameColors.gold,
  );

  static const ace = HuntLevel(
    id: 4,
    name: 'ACE',
    blurb: 'A wide arena. Stay sharp.',
    minValue: 1,
    maxValue: 500,
    maxAttempts: 12,
    pointsToUnlock: 360,
    multiplier: 2,
    accent: GameColors.magenta,
  );

  static const phantom = HuntLevel(
    id: 5,
    name: 'PHANTOM',
    blurb: 'The deepest hunt. 1 to 1000.',
    minValue: 1,
    maxValue: 1000,
    maxAttempts: 12,
    pointsToUnlock: 650,
    multiplier: 2.5,
    accent: GameColors.violet,
  );

  static const List<HuntLevel> seedAll = [
    scout,
    hunter,
    ranger,
    ace,
    phantom,
  ];

  static List<HuntLevel>? _apiAll;

  static List<HuntLevel> get all => _apiAll ?? seedAll;

  static void applyLevels(List<HuntLevel> levels) {
    _apiAll = List<HuntLevel>.unmodifiable(levels);
  }

  static HuntLevel byId(int id) {
    return all.firstWhere((level) => level.id == id, orElse: () => scout);
  }

  HuntLevel? get next {
    final index = all.indexWhere((level) => level.id == id);
    if (index < 0 || index >= all.length - 1) return null;
    return all[index + 1];
  }

  bool get isLast => next == null;
}
