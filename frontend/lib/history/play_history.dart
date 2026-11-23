import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:guess_game/catalog/game_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayHistoryEntry {
  const PlayHistoryEntry({
    required this.id,
    required this.gameId,
    required this.resultLabel,
    required this.headline,
    required this.summary,
    required this.playedAt,
    this.won,
    this.detail,
  });

  final String id;
  final String gameId;
  final String resultLabel;
  final String headline;
  final String summary;
  final DateTime playedAt;
  final bool? won;
  final String? detail;

  String get gameTitle {
    final game = GameCatalog.gameById(gameId);
    return game?.title ?? gameId.toUpperCase();
  }

  String ageLabel([DateTime? now]) {
    final elapsed = (now ?? DateTime.now()).difference(playedAt);
    if (elapsed.inSeconds < 45) return 'JUST NOW';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}M AGO';
    if (elapsed.inHours < 24) return '${elapsed.inHours}H AGO';
    return '${elapsed.inDays}D AGO';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'resultLabel': resultLabel,
        'headline': headline,
        'summary': summary,
        'playedAt': playedAt.toIso8601String(),
        'won': won,
        'detail': detail,
      };

  factory PlayHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PlayHistoryEntry(
      id: json['id'] as String? ??
          '${json['gameId']}_${json['playedAt']}',
      gameId: json['gameId'] as String? ?? 'unknown',
      resultLabel: json['resultLabel'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      playedAt: DateTime.tryParse(json['playedAt'] as String? ?? '') ??
          DateTime.now(),
      won: json['won'] as bool?,
      detail: json['detail'] as String?,
    );
  }
}

class PlayHistoryStore extends ChangeNotifier {
  PlayHistoryStore._();

  static final PlayHistoryStore instance = PlayHistoryStore._();

  static const _key = 'play_history_v1';
  static const _migratedKey = 'play_history_migrated_v1';
  static const _maxEntries = 200;

  final List<PlayHistoryEntry> _entries = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<PlayHistoryEntry> get entries => List.unmodifiable(_entries);

  List<PlayHistoryEntry> filtered({String? gameId}) {
    if (gameId == null || gameId.isEmpty) return entries;
    return _entries.where((e) => e.gameId == gameId).toList(growable: false);
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    _entries
      ..clear()
      ..addAll(
        raw.map(
          (item) => PlayHistoryEntry.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        ),
      );
    _loaded = true;
    notifyListeners();
  }

  Future<bool> needsLegacyMigration() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_migratedKey) ?? false);
  }

  Future<void> markLegacyMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migratedKey, true);
  }

  Future<void> importLegacy(List<PlayHistoryEntry> legacy) async {
    await ensureLoaded();
    if (legacy.isEmpty) return;
    final existingIds = _entries.map((e) => e.id).toSet();
    final incoming =
        legacy.where((e) => !existingIds.contains(e.id)).toList(growable: false);
    if (incoming.isEmpty) return;
    _entries.addAll(incoming);
    _entries.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
    notifyListeners();
  }

  Future<void> add(PlayHistoryEntry entry) async {
    await ensureLoaded();
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
    notifyListeners();
  }

  Future<void> record({
    required String gameId,
    required String resultLabel,
    required String headline,
    required String summary,
    bool? won,
    String? detail,
    DateTime? playedAt,
  }) {
    final at = playedAt ?? DateTime.now();
    return add(
      PlayHistoryEntry(
        id: '${gameId}_${at.microsecondsSinceEpoch}',
        gameId: gameId,
        resultLabel: resultLabel,
        headline: headline,
        summary: summary,
        playedAt: at,
        won: won,
        detail: detail,
      ),
    );
  }

  Future<void> clear({String? gameId}) async {
    await ensureLoaded();
    if (gameId == null || gameId.isEmpty) {
      _entries.clear();
    } else {
      _entries.removeWhere((e) => e.gameId == gameId);
    }
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
    notifyListeners();
  }

  Future<void> _persist(SharedPreferences prefs) async {
    await prefs.setStringList(
      _key,
      _entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
