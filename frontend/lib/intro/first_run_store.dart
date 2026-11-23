import 'package:shared_preferences/shared_preferences.dart';

/// One-time intro / tip flags. Each [id] is shown at most once per install.
class FirstRunStore {
  FirstRunStore._();

  static final FirstRunStore instance = FirstRunStore._();

  static const hubWelcomeId = 'intro_hub_welcome_v1';
  static const numberHunterId = 'intro_number_hunter_v1';
  static const cricketBattleId = 'intro_cricket_battle_v1';
  static const privateRoomId = 'intro_private_room_v1';
  static const profileStreakId = 'intro_profile_streak_v1';

  /// Coach-mark / feature-tip ids (short tooltip callouts).
  static const tipPuzzlesId = 'tip_puzzles_v1';
  static const tipPrivateRoomId = 'tip_private_room_v1';
  static const tipCardGamesId = 'tip_card_games_v1';

  static const _prefix = 'playora_intro_seen_';

  final Set<String> _seen = {};
  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _seen
      ..clear()
      ..addAll(
        prefs.getKeys().where((key) => key.startsWith(_prefix)).map(
              (key) => key.substring(_prefix.length),
            ),
      );
    loaded = true;
  }

  bool hasSeen(String id) => _seen.contains(id);

  Future<bool> shouldShow(String id) async {
    if (!loaded) await load();
    return !hasSeen(id);
  }

  Future<void> markSeen(String id) async {
    if (!loaded) await load();
    if (_seen.contains(id)) return;
    _seen.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$id', true);
  }
}
