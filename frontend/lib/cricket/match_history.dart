import 'dart:convert';

import 'package:guess_game/catalog/game_catalog.dart';
import 'package:guess_game/history/play_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchHistoryEntry {
  const MatchHistoryEntry({
    required this.summary,
    required this.venueName,
    required this.scoreline,
    required this.userWon,
    required this.tied,
    required this.playedAt,
  });

  final String summary;
  final String venueName;
  final String scoreline;
  final bool userWon;
  final bool tied;
  final DateTime playedAt;

  String get resultLabel {
    if (tied) return 'TIE';
    return userWon ? 'WIN' : 'LOSS';
  }

  String ageLabel([DateTime? now]) {
    final elapsed = (now ?? DateTime.now()).difference(playedAt);
    if (elapsed.inSeconds < 45) return 'JUST NOW';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}M AGO';
    if (elapsed.inHours < 24) return '${elapsed.inHours}H AGO';
    return '${elapsed.inDays}D AGO';
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'venueName': venueName,
        'scoreline': scoreline,
        'userWon': userWon,
        'tied': tied,
        'playedAt': playedAt.toIso8601String(),
      };

  factory MatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MatchHistoryEntry(
      summary: json['summary'] as String? ?? '',
      venueName: json['venueName'] as String? ?? 'Unknown ground',
      scoreline: json['scoreline'] as String? ?? '',
      userWon: json['userWon'] as bool? ?? false,
      tied: json['tied'] as bool? ?? false,
      playedAt: DateTime.tryParse(json['playedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class MatchHistoryStore {
  static const _key = 'cricket_match_history_v1';
  static const _maxEntries = 50;

  static Future<List<MatchHistoryEntry>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    return raw
        .map((item) => MatchHistoryEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            ))
        .toList();
  }

  static Future<List<MatchHistoryEntry>> latest({int limit = 5}) async {
    final entries = await all();
    return entries.take(limit).toList();
  }

  static Future<void> add(MatchHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final next = <String>[
      jsonEncode(entry.toJson()),
      ...raw,
    ];
    await prefs.setStringList(_key, next.take(_maxEntries).toList());
    await PlayHistoryStore.instance.record(
      gameId: GameCatalog.cricketId,
      resultLabel: entry.resultLabel,
      headline: entry.scoreline,
      summary: entry.summary.isEmpty ? entry.venueName : entry.summary,
      won: entry.tied ? null : entry.userWon,
      detail: entry.venueName,
      playedAt: entry.playedAt,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
