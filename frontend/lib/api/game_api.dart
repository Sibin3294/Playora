import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:guess_game/game/guess_engine.dart';
import 'package:guess_game/game/hunt_archive.dart';
import 'package:guess_game/game/hunt_level.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.id,
    required this.totalPoints,
    required this.campaignCleared,
    required this.selectedLevelId,
    this.email,
    this.name,
    this.isGuest = true,
  });

  final String id;
  final int totalPoints;
  final bool campaignCleared;
  final int selectedLevelId;
  final String? email;
  final String? name;
  final bool isGuest;
}

class AuthResult {
  const AuthResult({required this.token, required this.player});

  final String token;
  final PlayerSnapshot player;
}

class StartResult {
  const StartResult({
    required this.gameId,
    required this.engine,
    required this.player,
  });

  final String gameId;
  final GuessEngine engine;
  final PlayerSnapshot player;
}

class GuessResponse {
  const GuessResponse({
    required this.engine,
    required this.player,
    required this.unlockedLevels,
    required this.pointsEarned,
    required this.campaignBonus,
  });

  final GuessEngine engine;
  final PlayerSnapshot player;
  final List<HuntLevel> unlockedLevels;
  final int pointsEarned;
  final int campaignBonus;
}

class GameApi {
  GameApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;
  String? authToken;

  /// Production / Render: `--dart-define=API_BASE=https://playora-api.onrender.com`
  static const String apiBase = String.fromEnvironment('API_BASE');

  /// Override when building: `--dart-define=API_HOST=10.0.2.2` (emulator)
  /// or `--dart-define=API_HOST=192.168.x.x` (phone on same Wi‑Fi).
  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.29.52',
  );

  static const String apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '3100',
  );

  static String get _defaultBaseUrl {
    if (apiBase.trim().isNotEmpty) return apiBase.trim();
    if (kIsWeb) {
      return 'http://127.0.0.1:$apiPort';
    }
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://$apiHost:$apiPort';
    }
    return 'http://127.0.0.1:$apiPort';
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final body = await _post('/api/auth/register', {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    return AuthResult(
      token: body['token'] as String,
      player: _player(body['player'] as Map<String, dynamic>),
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final body = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthResult(
      token: body['token'] as String,
      player: _player(body['player'] as Map<String, dynamic>),
    );
  }

  Future<PlayerSnapshot> me() async {
    final body = await _send('GET', '/api/auth/me');
    return _player(body['player'] as Map<String, dynamic>);
  }

  Future<PlayerSnapshot> updateProfile({required String name}) async {
    final body = await _send('PATCH', '/api/auth/me', {'name': name});
    return _player(body['player'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _post('/api/auth/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<PlayerSnapshot> upsertPlayer(String deviceId) async {
    final body = await _post('/api/players', {'deviceId': deviceId});
    return _player(body['player'] as Map<String, dynamic>);
  }

  Future<PlayerSnapshot> updatePlayer(
    String playerId, {
    int? selectedLevelId,
    String? name,
  }) async {
    final body = await _send(
      'PATCH',
      '/api/players/$playerId',
      {
        if (selectedLevelId != null) 'selectedLevelId': selectedLevelId,
        if (name != null) 'name': name,
      },
    );
    return _player(body['player'] as Map<String, dynamic>);
  }

  Future<PlayerSnapshot> selectLevel(String playerId, int levelId) async {
    return updatePlayer(playerId, selectedLevelId: levelId);
  }

  Future<StartResult> startGame({
    required String playerId,
    required int levelId,
  }) async {
    final body = await _post('/api/games', {
      'playerId': playerId,
      'levelId': levelId,
    });
    final game = body['game'] as Map<String, dynamic>;
    return StartResult(
      gameId: game['id'] as String,
      engine: _engine(game),
      player: _player(body['player'] as Map<String, dynamic>),
    );
  }

  Future<GuessResponse> submitGuess({
    required String gameId,
    required int value,
  }) async {
    final body = await _post('/api/games/$gameId/guesses', {'value': value});
    final game = body['game'] as Map<String, dynamic>;
    final unlocked = (body['unlockedLevelIds'] as List<dynamic>? ?? [])
        .map((id) => HuntLevel.byId(id as int))
        .toList();
    return GuessResponse(
      engine: _engine(game),
      player: _player(body['player'] as Map<String, dynamic>),
      unlockedLevels: unlocked,
      pointsEarned: game['pointsEarned'] as int? ?? 0,
      campaignBonus: game['campaignBonus'] as int? ?? 0,
    );
  }

  Future<List<HuntRecord>> history(String playerId) async {
    final body = await _send('GET', '/api/players/$playerId/games');
    final games = body['games'] as List<dynamic>? ?? [];
    return games.map((item) => _record(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createRoom({
    required String playerId,
    String? name,
  }) async {
    final body = await _post('/api/rooms', {
      'playerId': playerId,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    return body['room'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinRoom({
    required String code,
    required String playerId,
    String? name,
  }) async {
    final body = await _post('/api/rooms/join', {
      'code': code,
      'playerId': playerId,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    return body['room'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRoom({
    required String code,
    required String playerId,
  }) async {
    final body = await _send(
      'GET',
      '/api/rooms/$code?playerId=${Uri.encodeQueryComponent(playerId)}',
    );
    return body['room'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitRoomSquad({
    required String code,
    required String playerId,
    required Map<String, dynamic> squad,
  }) async {
    final body = await _post('/api/rooms/$code/squad', {
      'playerId': playerId,
      'squad': squad,
    });
    return body['room'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setRoomReady({
    required String code,
    required String playerId,
    bool ready = true,
  }) async {
    final body = await _post('/api/rooms/$code/ready', {
      'playerId': playerId,
      'ready': ready,
    });
    return body['room'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitRoomMatch({
    required String code,
    required String playerId,
    required Map<String, dynamic> matchResult,
  }) async {
    final body = await _post('/api/rooms/$code/match', {
      'playerId': playerId,
      'matchResult': matchResult,
    });
    return body['room'] as Map<String, dynamic>;
  }

  /// Full gameplay content catalog (levels, rosters, venues, puzzles, hub).
  Future<Map<String, dynamic>> fetchCatalog() async {
    final body = await _send('GET', '/api/catalog');
    return body['catalog'] as Map<String, dynamic>? ?? body;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> json) {
    return _send('POST', path, json);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? json,
  ]) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };
    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(json))
              .timeout(const Duration(seconds: 8));
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(json))
              .timeout(const Duration(seconds: 8));
        default:
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 8));
      }
    } catch (_) {
      throw ApiException(
        'Cannot reach hunt server at $baseUrl. '
        'Keep the API running and use the same Wi‑Fi.',
      );
    }
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(
        decoded['error'] as String? ?? 'The hunt server rejected that.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  PlayerSnapshot _player(Map<String, dynamic> json) {
    return PlayerSnapshot(
      id: json['id'] as String,
      totalPoints: json['totalPoints'] as int? ?? 0,
      campaignCleared: json['campaignCleared'] as bool? ?? false,
      selectedLevelId: json['selectedLevelId'] as int? ?? 1,
      email: json['email'] as String?,
      name: json['name'] as String?,
      isGuest: json['isGuest'] as bool? ?? (json['email'] == null),
    );
  }

  GuessEngine _engine(Map<String, dynamic> json) {
    final level = HuntLevel.byId(json['levelId'] as int);
    final secret = json['secretNumber'] as int?;
    final engine = GuessEngine(
      secretNumber: secret ?? level.minValue,
      minValue: json['minValue'] as int? ?? level.minValue,
      maxValue: json['maxValue'] as int? ?? level.maxValue,
      maxAttempts: json['maxAttempts'] as int? ?? level.maxAttempts,
      level: level,
      providedHints: (json['hints'] as List<dynamic>? ?? [])
          .map((hint) => hint as String)
          .toList(),
      closestOverride: json['closestDistance'] as int?,
    );
    engine.lowBound = json['lowBound'] as int? ?? level.minValue;
    engine.highBound = json['highBound'] as int? ?? level.maxValue;
    final guesses = json['guesses'] as List<dynamic>? ?? [];
    for (final item in guesses) {
      final guess = item as Map<String, dynamic>;
      engine.guesses.add(
        GuessAttempt(
          value: guess['value'] as int,
          direction: _direction(guess['direction'] as String),
          heat: _heat(guess['heat'] as String),
        ),
      );
    }
    return engine;
  }

  HuntRecord _record(Map<String, dynamic> json) {
    final guesses = (json['guesses'] as List<dynamic>? ?? []).map((item) {
      final guess = item as Map<String, dynamic>;
      return GuessAttempt(
        value: guess['value'] as int,
        direction: _direction(guess['direction'] as String),
        heat: _heat(guess['heat'] as String),
      );
    }).toList();
    final created = DateTime.tryParse(json['createdAt'] as String? ?? '');
    return HuntRecord(
      won: json['status'] == 'won',
      secretNumber: json['secretNumber'] as int? ?? 0,
      guesses: guesses,
      attemptsUsed: json['attemptsUsed'] as int? ?? guesses.length,
      maxAttempts: json['maxAttempts'] as int? ?? 12,
      closestDistance: json['closestDistance'] as int? ?? 0,
      playedAt: created ?? DateTime.now(),
      levelName: HuntLevel.byId(json['levelId'] as int? ?? 1).name,
      points: (json['pointsEarned'] as int? ?? 0) +
          (json['campaignBonus'] as int? ?? 0),
    );
  }

  GuessDirection _direction(String value) {
    switch (value) {
      case 'tooHigh':
        return GuessDirection.tooHigh;
      case 'correct':
        return GuessDirection.correct;
      default:
        return GuessDirection.tooLow;
    }
  }

  Heat _heat(String value) {
    switch (value) {
      case 'chilly':
        return Heat.chilly;
      case 'warm':
        return Heat.warm;
      case 'hot':
        return Heat.hot;
      case 'scorching':
        return Heat.scorching;
      default:
        return Heat.ice;
    }
  }
}
