import 'package:guess_game/cards/trump_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Level-wise Stat Battle progression.
class TrumpLevels {
  static const seedMaxLevel = 5;
  static const seedMaxStats = 15;
  static const seedMaxCards = 50;
  static const seedPicksPerAdvance = 3;
  static const seedDeckSizes = <int>[10, 18, 28, 40, 50];

  static int? _apiMaxLevel;
  static int? _apiMaxStats;
  static int? _apiMaxCards;
  static int? _apiPicksPerAdvance;
  static List<int>? _apiDeckSizes;
  static List<TrumpStat>? _apiStarterStats;

  static int get maxLevel => _apiMaxLevel ?? seedMaxLevel;
  static int get maxStats => _apiMaxStats ?? seedMaxStats;
  static int get maxCards => _apiMaxCards ?? seedMaxCards;
  static int get picksPerAdvance =>
      _apiPicksPerAdvance ?? seedPicksPerAdvance;

  static const seedStarterStats = <TrumpStat>[
    TrumpStat.bat,
    TrumpStat.bowl,
    TrumpStat.field,
    TrumpStat.overall,
  ];

  static List<TrumpStat> get starterStats =>
      _apiStarterStats ?? seedStarterStats;

  static void applyConfig({
    int? maxLevel,
    int? maxStats,
    int? maxCards,
    int? picksPerAdvance,
    List<int>? deckSizes,
    List<TrumpStat>? starterStats,
  }) {
    if (maxLevel != null) _apiMaxLevel = maxLevel;
    if (maxStats != null) _apiMaxStats = maxStats;
    if (maxCards != null) _apiMaxCards = maxCards;
    if (picksPerAdvance != null) _apiPicksPerAdvance = picksPerAdvance;
    if (deckSizes != null && deckSizes.isNotEmpty) {
      _apiDeckSizes = List<int>.unmodifiable(deckSizes);
    }
    if (starterStats != null && starterStats.isNotEmpty) {
      _apiStarterStats = List<TrumpStat>.unmodifiable(starterStats);
    }
  }

  /// Unlockable pool (everything except the fixed starters).
  static List<TrumpStat> get masterPool => TrumpStat.values
      .where((stat) => !starterStats.contains(stat))
      .toList(growable: false);

  static int statsForLevel(int level) {
    final raw = starterStats.length + (level - 1) * picksPerAdvance;
    return raw.clamp(starterStats.length, maxStats);
  }

  static int deckSizeForLevel(int level) {
    final sizes = _apiDeckSizes ?? seedDeckSizes;
    final index = level.clamp(1, maxLevel) - 1;
    final size = sizes[index.clamp(0, sizes.length - 1)];
    return size.clamp(2, maxCards);
  }

  /// New stats the player must pick when first entering [level].
  static int picksNeededForLevel(int level) {
    if (level <= 1) return 0;
    return statsForLevel(level) - statsForLevel(level - 1);
  }

  static bool isFinalLevel(int level) => level >= maxLevel;
}

class TrumpWinTimeResult {
  const TrumpWinTimeResult({
    required this.elapsed,
    required this.previousBest,
    required this.previousLast,
    required this.isNewBest,
    required this.beatLastWin,
  });

  final Duration elapsed;
  final Duration? previousBest;
  final Duration? previousLast;
  final bool isNewBest;
  final bool beatLastWin;
}

class TrumpProgression {
  TrumpProgression._();

  static final TrumpProgression instance = TrumpProgression._();

  static const _unlockedKey = 'playora_trump_unlocked_level_v1';
  static const _ownedKey = 'playora_trump_owned_stats_v1';
  static const _clearedKey = 'playora_trump_cleared_levels_v1';
  static const _bestTimePrefix = 'playora_trump_best_ms_v1_l';
  static const _lastTimePrefix = 'playora_trump_last_ms_v1_l';

  int unlockedLevel = 1;
  List<TrumpStat> ownedStats = List<TrumpStat>.from(TrumpLevels.starterStats);
  final Set<int> clearedLevels = {};
  final Map<int, Duration> bestWinTimes = {};
  final Map<int, Duration> lastWinTimes = {};

  bool loaded = false;

  static String formatDuration(Duration d) {
    final totalSec = d.inSeconds.clamp(0, 359999);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    unlockedLevel =
        (prefs.getInt(_unlockedKey) ?? 1).clamp(1, TrumpLevels.maxLevel);

    final saved = prefs.getStringList(_ownedKey);
    if (saved == null || saved.isEmpty) {
      ownedStats = List<TrumpStat>.from(TrumpLevels.starterStats);
    } else {
      final parsed = <TrumpStat>[
        for (final name in saved)
          if (TrumpStat.tryParse(name) != null) TrumpStat.tryParse(name)!,
      ];
      // Always keep starters first.
      ownedStats = [
        ...TrumpLevels.starterStats,
        ...parsed.where((s) => !TrumpLevels.starterStats.contains(s)),
      ];
    }

    clearedLevels
      ..clear()
      ..addAll(
        (prefs.getStringList(_clearedKey) ?? const <String>[])
            .map(int.tryParse)
            .whereType<int>(),
      );

    bestWinTimes.clear();
    lastWinTimes.clear();
    for (var level = 1; level <= TrumpLevels.maxLevel; level++) {
      final bestMs = prefs.getInt('$_bestTimePrefix$level');
      if (bestMs != null && bestMs > 0) {
        bestWinTimes[level] = Duration(milliseconds: bestMs);
      }
      final lastMs = prefs.getInt('$_lastTimePrefix$level');
      if (lastMs != null && lastMs > 0) {
        lastWinTimes[level] = Duration(milliseconds: lastMs);
      }
    }

    loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedKey, unlockedLevel);
    await prefs.setStringList(
      _ownedKey,
      [for (final stat in ownedStats) stat.name],
    );
    await prefs.setStringList(
      _clearedKey,
      [for (final level in clearedLevels) '$level'],
    );
    for (final entry in bestWinTimes.entries) {
      await prefs.setInt(
        '$_bestTimePrefix${entry.key}',
        entry.value.inMilliseconds,
      );
    }
    for (final entry in lastWinTimes.entries) {
      await prefs.setInt(
        '$_lastTimePrefix${entry.key}',
        entry.value.inMilliseconds,
      );
    }
  }

  Duration? bestWinTime(int level) => bestWinTimes[level];

  Duration? lastWinTime(int level) => lastWinTimes[level];

  Future<void> ensureLoaded() async {
    if (!loaded) await load();
  }

  bool isUnlocked(int level) => level >= 1 && level <= unlockedLevel;

  bool isCleared(int level) => clearedLevels.contains(level);

  List<TrumpStat> statsForLevel(int level) {
    final count = TrumpLevels.statsForLevel(level);
    if (ownedStats.length >= count) {
      return ownedStats.take(count).toList(growable: false);
    }
    return List<TrumpStat>.from(ownedStats);
  }

  bool needsStatPick(int level) {
    if (level <= 1) return false;
    return ownedStats.length < TrumpLevels.statsForLevel(level);
  }

  List<TrumpStat> availableToPick() {
    final owned = ownedStats.toSet();
    return TrumpLevels.masterPool
        .where((stat) => !owned.contains(stat))
        .toList(growable: false);
  }

  Future<void> appendPicks(List<TrumpStat> picks) async {
    await ensureLoaded();
    for (final stat in picks) {
      if (TrumpLevels.starterStats.contains(stat)) continue;
      if (ownedStats.contains(stat)) continue;
      if (ownedStats.length >= TrumpLevels.maxStats) break;
      ownedStats.add(stat);
    }
    await _save();
  }

  /// Call after the user wins [level]. Unlocks the next level when ready.
  /// Returns whether the next level was newly unlocked.
  Future<({bool unlockedNext, TrumpWinTimeResult time})> recordWin(
    int level, {
    required Duration elapsed,
  }) async {
    await ensureLoaded();
    clearedLevels.add(level);
    var unlockedNext = false;
    if (level >= unlockedLevel && level < TrumpLevels.maxLevel) {
      unlockedLevel = level + 1;
      unlockedNext = true;
    }

    final previousBest = bestWinTimes[level];
    final previousLast = lastWinTimes[level];
    final isNewBest =
        previousBest == null || elapsed < previousBest;
    final beatLastWin =
        previousLast != null && elapsed < previousLast;

    lastWinTimes[level] = elapsed;
    if (isNewBest) {
      bestWinTimes[level] = elapsed;
    }

    await _save();
    return (
      unlockedNext: unlockedNext,
      time: TrumpWinTimeResult(
        elapsed: elapsed,
        previousBest: previousBest,
        previousLast: previousLast,
        isNewBest: isNewBest,
        beatLastWin: beatLastWin,
      ),
    );
  }
}
