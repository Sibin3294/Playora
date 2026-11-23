import 'package:flutter/foundation.dart';
import 'package:guess_game/api/game_api.dart';
import 'package:guess_game/catalog/catalog_cache.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:guess_game/game/player_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSession extends ChangeNotifier {
  GameSession({GameApi? api}) : api = api ?? GameApi();

  static final GameSession instance = GameSession();

  /// On-device play with no hunt API. Enable via
  /// `--dart-define=FORCE_LOCAL=true` (APK/tests).
  static bool forceLocal =
      const bool.fromEnvironment('FORCE_LOCAL', defaultValue: false);

  final GameApi api;
  String? playerId;
  String? token;
  String? email;
  String? name;
  bool isGuest = true;
  bool ready = false;
  bool bootstrapped = false;
  bool offline = false;
  String? lastError;

  bool get isLoggedIn => token != null && token!.isNotEmpty && !isGuest;

  Future<void> bootstrap() async {
    if (forceLocal) {
      bootstrapped = true;
      notifyListeners();
      return;
    }
    await loadCatalog();
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedToken = preferences.getString('authToken');
      if (savedToken != null && savedToken.isNotEmpty) {
        api.authToken = savedToken;
        token = savedToken;
        final player = await api.me();
        await _persistAuth(token: savedToken, player: player);
        await _loadHistory(player.id);
        ready = true;
        lastError = null;
      } else {
        ready = false;
      }
    } catch (error) {
      await logout(silent: true);
      ready = false;
      lastError = error.toString();
    }
    bootstrapped = true;
    notifyListeners();
  }

  /// Loads gameplay catalogs from the API. Keeps local seeds on failure.
  Future<bool> loadCatalog() async {
    if (forceLocal) return false;
    try {
      final catalog = await api.fetchCatalog();
      CatalogCache.instance.applyApiCatalog(catalog);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final result = await api.register(
      email: email,
      password: password,
      name: name,
    );
    await _finishAuth(result);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final result = await api.login(email: email, password: password);
    await _finishAuth(result);
  }

  Future<void> continueAsGuest() async {
    final preferences = await SharedPreferences.getInstance();
    var deviceId = preferences.getString('deviceId');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = 'hunter-${DateTime.now().microsecondsSinceEpoch}';
      await preferences.setString('deviceId', deviceId);
    }
    api.authToken = null;
    token = null;
    await preferences.remove('authToken');

    try {
      final player = await api.upsertPlayer(deviceId);
      await preferences.setString('playerId', player.id);
      _apply(player);
      try {
        await _loadHistory(player.id);
      } catch (_) {
        // Keep local archive if history sync fails.
      }
      offline = false;
      lastError = null;
    } catch (_) {
      // Real phones cannot reach 10.0.2.2 / localhost — play on-device.
      await _startOfflineGuest(deviceId);
    }
    ready = true;
    bootstrapped = true;
    notifyListeners();
  }

  bool get hasServerPlayer =>
      playerId != null &&
      playerId!.isNotEmpty &&
      !playerId!.startsWith('local-');

  /// Reconnects a guest/offline session to the hunt API when possible.
  /// Returns true when Number Hunter can run against the server.
  Future<bool> ensureServerSession() async {
    if (forceLocal) return false;
    if (isLoggedIn && hasServerPlayer && !offline) return true;
    if (!isLoggedIn && hasServerPlayer && !offline && ready) return true;

    final preferences = await SharedPreferences.getInstance();
    if (isLoggedIn && token != null) {
      try {
        api.authToken = token;
        final player = await api.me();
        await _persistAuth(token: token!, player: player);
        await _loadHistory(player.id);
        offline = false;
        ready = true;
        lastError = null;
        notifyListeners();
        return true;
      } catch (error) {
        lastError = error.toString();
        notifyListeners();
        return false;
      }
    }

    var deviceId = preferences.getString('deviceId');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = 'hunter-${DateTime.now().microsecondsSinceEpoch}';
      await preferences.setString('deviceId', deviceId);
    }

    try {
      api.authToken = null;
      final player = await api.upsertPlayer(deviceId);
      await preferences.setString('playerId', player.id);
      _apply(player);
      try {
        await _loadHistory(player.id);
      } catch (_) {}
      offline = false;
      ready = true;
      lastError = null;
      notifyListeners();
      return true;
    } catch (error) {
      if (!ready || playerId == null) {
        await _startOfflineGuest(deviceId);
        ready = true;
      } else {
        offline = true;
      }
      lastError = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _startOfflineGuest(String deviceId) async {
    final preferences = await SharedPreferences.getInstance();
    final localId = preferences.getString('playerId') ?? 'local-$deviceId';
    await preferences.setString('playerId', localId);
    playerId = localId;
    email = null;
    name = 'Offline Hunter';
    isGuest = true;
    offline = true;
    lastError = null;
  }

  Future<void> logout({bool silent = false}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('authToken');
    api.authToken = null;
    token = null;
    email = null;
    name = null;
    playerId = null;
    isGuest = true;
    ready = false;
    offline = false;
    HuntArchive.instance.clear();
    PlayerProgress.instance.reset();
    if (!silent) {
      lastError = null;
      notifyListeners();
    }
  }

  Future<void> selectLevel(HuntLevel level) async {
    final progress = PlayerProgress.instance;
    if (!progress.isUnlocked(level)) return;
    progress.select(level);
    if (!ready || playerId == null || offline) return;
    try {
      _apply(await api.selectLevel(playerId!, level.id));
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  void applyPlayer(PlayerSnapshot player) => _apply(player);

  Future<void> refreshProfile() async {
    if (forceLocal || offline || !ready) return;
    if (isLoggedIn) {
      final player = await api.me();
      _apply(player);
      notifyListeners();
      return;
    }
    if (playerId == null) return;
    // Guest profiles stay local unless the player id is a server id.
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ApiException('Name is required.');
    }
    if (offline || forceLocal) {
      this.name = trimmed;
      notifyListeners();
      return;
    }
    if (isLoggedIn) {
      _apply(await api.updateProfile(name: trimmed));
      notifyListeners();
      return;
    }
    if (playerId == null) {
      throw ApiException('No player session.');
    }
    _apply(await api.updatePlayer(playerId!, name: trimmed));
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isLoggedIn) {
      throw ApiException('Sign in to change your password.');
    }
    await api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> _finishAuth(AuthResult result) async {
    await _persistAuth(token: result.token, player: result.player);
    await _loadHistory(result.player.id);
    ready = true;
    lastError = null;
    bootstrapped = true;
    notifyListeners();
  }

  Future<void> _persistAuth({
    required String token,
    required PlayerSnapshot player,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('authToken', token);
    await preferences.setString('playerId', player.id);
    api.authToken = token;
    this.token = token;
    _apply(player);
  }

  Future<void> _loadHistory(String id) async {
    final hunts = await api.history(id);
    HuntArchive.instance.replaceAll(hunts.reversed.toList());
  }

  void _apply(PlayerSnapshot player) {
    playerId = player.id;
    email = player.email;
    name = player.name;
    isGuest = player.isGuest;
    PlayerProgress.instance.applyRemote(
      totalPoints: player.totalPoints,
      selectedLevelId: player.selectedLevelId,
      campaignCleared: player.campaignCleared,
    );
  }
}
