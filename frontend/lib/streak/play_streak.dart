import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StreakTag {
  none(label: '', daysRequired: 0),
  bronze(label: 'BRONZE', daysRequired: 7),
  silver(label: 'SILVER', daysRequired: 15),
  gold(label: 'GOLD', daysRequired: 30);

  const StreakTag({required this.label, required this.daysRequired});

  final String label;
  final int daysRequired;

  static StreakTag forStreak(int days) {
    if (days >= StreakTag.gold.daysRequired) return StreakTag.gold;
    if (days >= StreakTag.silver.daysRequired) return StreakTag.silver;
    if (days >= StreakTag.bronze.daysRequired) return StreakTag.bronze;
    return StreakTag.none;
  }

  static StreakTag higher(StreakTag a, StreakTag b) =>
      a.index >= b.index ? a : b;
}

class PlayStreakResult {
  const PlayStreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.earnedTag,
    required this.isNewPlayDay,
    required this.tagJustUnlocked,
  });

  final int currentStreak;
  final int longestStreak;
  final StreakTag earnedTag;
  final bool isNewPlayDay;
  final StreakTag? tagJustUnlocked;
}

/// Tracks consecutive calendar-day play across any game category.
class PlayStreakStore extends ChangeNotifier {
  PlayStreakStore._();

  static final PlayStreakStore instance = PlayStreakStore._();

  static const _streakKey = 'playora_streak_current_v1';
  static const _longestKey = 'playora_streak_longest_v1';
  static const _lastDayKey = 'playora_streak_last_day_v1';
  static const _tagKey = 'playora_streak_tag_v1';

  int currentStreak = 0;
  int longestStreak = 0;
  StreakTag earnedTag = StreakTag.none;
  String? lastPlayDay;
  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    currentStreak = prefs.getInt(_streakKey) ?? 0;
    longestStreak = prefs.getInt(_longestKey) ?? 0;
    lastPlayDay = prefs.getString(_lastDayKey);
    final tagName = prefs.getString(_tagKey);
    earnedTag = StreakTag.values.firstWhere(
      (tag) => tag.name == tagName,
      orElse: () => StreakTag.forStreak(longestStreak),
    );
    // Soft-break display if they already missed today/yesterday.
    currentStreak = _effectiveCurrentStreak(DateTime.now());
    loaded = true;
    notifyListeners();
  }

  int _effectiveCurrentStreak(DateTime now) {
    if (lastPlayDay == null || currentStreak <= 0) return 0;
    final last = _parseDay(lastPlayDay!);
    if (last == null) return 0;
    final today = _dateOnly(now);
    final delta = today.difference(last).inDays;
    if (delta == 0 || delta == 1) return currentStreak;
    return 0;
  }

  /// Call when the user opens any playable game. Shows streak UI only on a
  /// new calendar day of activity.
  Future<PlayStreakResult> recordPlay({DateTime? now}) async {
    if (!loaded) await load();
    final moment = now ?? DateTime.now();
    final today = _dateOnly(moment);
    final todayKey = _dayKey(today);

    if (lastPlayDay == todayKey) {
      return PlayStreakResult(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        earnedTag: earnedTag,
        isNewPlayDay: false,
        tagJustUnlocked: null,
      );
    }

    final last = lastPlayDay == null ? null : _parseDay(lastPlayDay!);
    var nextStreak = 1;
    if (last != null) {
      final gap = today.difference(last).inDays;
      if (gap == 1) {
        nextStreak = currentStreak + 1;
      } else {
        nextStreak = 1;
      }
    }

    final previousTag = earnedTag;
    currentStreak = nextStreak;
    if (currentStreak > longestStreak) longestStreak = currentStreak;
    lastPlayDay = todayKey;
    earnedTag = StreakTag.higher(earnedTag, StreakTag.forStreak(currentStreak));
    await _persist();
    notifyListeners();

    final unlocked = earnedTag.index > previousTag.index ? earnedTag : null;
    return PlayStreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      earnedTag: earnedTag,
      isNewPlayDay: true,
      tagJustUnlocked: unlocked,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, currentStreak);
    await prefs.setInt(_longestKey, longestStreak);
    if (lastPlayDay != null) {
      await prefs.setString(_lastDayKey, lastPlayDay!);
    }
    await prefs.setString(_tagKey, earnedTag.name);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dayKey(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }

  static DateTime? _parseDay(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
