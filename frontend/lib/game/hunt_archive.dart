import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/history/play_history.dart';

class HuntRecord {
  HuntRecord({
    required this.won,
    required this.secretNumber,
    required this.guesses,
    required this.attemptsUsed,
    required this.maxAttempts,
    required this.closestDistance,
    required this.playedAt,
    this.levelName,
    this.points = 0,
  });

  factory HuntRecord.fromEngine(
    GuessEngine engine, {
    DateTime? playedAt,
    int? points,
  }) {
    return HuntRecord(
      won: engine.isWon,
      secretNumber: engine.secretNumber,
      guesses: List<GuessAttempt>.from(engine.guesses),
      attemptsUsed: engine.attemptsUsed,
      maxAttempts: engine.maxAttempts,
      closestDistance: engine.closestDistance,
      playedAt: playedAt ?? DateTime.now(),
      levelName: engine.level?.name,
      points: points ?? engine.pointsEarned,
    );
  }

  final bool won;
  final int secretNumber;
  final List<GuessAttempt> guesses;
  final int attemptsUsed;
  final int maxAttempts;
  final int closestDistance;
  final DateTime playedAt;
  final String? levelName;
  final int points;

  String get resultLabel => won ? 'WIN' : 'LOSS';

  String get summary {
    if (won) return 'Cracked in $attemptsUsed/$maxAttempts shots';
    return 'Closest shot was $closestDistance away';
  }

  String ageLabel([DateTime? now]) {
    final elapsed = (now ?? DateTime.now()).difference(playedAt);
    if (elapsed.inSeconds < 45) return 'JUST NOW';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}M AGO';
    if (elapsed.inHours < 24) return '${elapsed.inHours}H AGO';
    return '${elapsed.inDays}D AGO';
  }
}

class HuntArchive extends ChangeNotifier {
  HuntArchive();

  static final HuntArchive instance = HuntArchive();

  final List<HuntRecord> _records = [];

  List<HuntRecord> get records => List.unmodifiable(_records.reversed);

  int get huntCount => _records.length;
  int get wins => _records.where((record) => record.won).length;
  int get losses => huntCount - wins;

  int? get bestWin {
    final winning = _records.where((record) => record.won);
    if (winning.isEmpty) return null;
    return winning.map((record) => record.attemptsUsed).reduce(min);
  }

  void replaceAll(List<HuntRecord> records) {
    _records
      ..clear()
      ..addAll(records);
    notifyListeners();
  }

  void add(HuntRecord record) {
    _records.add(record);
    notifyListeners();
    PlayHistoryStore.instance.record(
      gameId: GameCatalog.numberHunterId,
      resultLabel: record.resultLabel,
      headline: '${record.secretNumber}',
      summary: record.summary,
      won: record.won,
      detail: record.levelName,
      playedAt: record.playedAt,
    );
  }

  void addFromEngine(GuessEngine engine, {int? points}) {
    add(HuntRecord.fromEngine(engine, points: points));
  }

  void clear() {
    _records.clear();
    notifyListeners();
  }
}
