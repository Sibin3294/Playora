import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryRatingSummary {
  const CategoryRatingSummary({
    required this.average,
    required this.count,
  });

  final double average;
  final int count;

  bool get hasRatings => count > 0;
}

/// Aggregated 1–5 star ratings per hub category.
class CategoryRatings extends ChangeNotifier {
  CategoryRatings._();

  static final CategoryRatings instance = CategoryRatings._();

  static const _sumPrefix = 'playora_cat_rating_sum_v1_';
  static const _countPrefix = 'playora_cat_rating_count_v1_';

  final Map<String, int> _sums = {};
  final Map<String, int> _counts = {};
  final Set<String> _promptedThisSession = {};

  bool loaded = false;

  Future<void> ensureLoaded() async {
    if (loaded) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_sumPrefix)) {
        final id = key.substring(_sumPrefix.length);
        _sums[id] = prefs.getInt(key) ?? 0;
      } else if (key.startsWith(_countPrefix)) {
        final id = key.substring(_countPrefix.length);
        _counts[id] = prefs.getInt(key) ?? 0;
      }
    }
    loaded = true;
    notifyListeners();
  }

  CategoryRatingSummary summaryFor(String categoryId) {
    final count = _counts[categoryId] ?? 0;
    if (count <= 0) {
      return const CategoryRatingSummary(average: 0, count: 0);
    }
    final sum = _sums[categoryId] ?? 0;
    return CategoryRatingSummary(average: sum / count, count: count);
  }

  bool shouldPrompt(String categoryId) =>
      !_promptedThisSession.contains(categoryId);

  void markPrompted(String categoryId) =>
      _promptedThisSession.add(categoryId);

  Future<void> addRating(String categoryId, int stars) async {
    final clamped = stars.clamp(1, 5);
    await ensureLoaded();
    _sums[categoryId] = (_sums[categoryId] ?? 0) + clamped;
    _counts[categoryId] = (_counts[categoryId] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_sumPrefix$categoryId', _sums[categoryId]!);
    await prefs.setInt('$_countPrefix$categoryId', _counts[categoryId]!);
    notifyListeners();
  }
}
