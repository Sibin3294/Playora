import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:playora_admin/config.dart';

class AdminApiException implements Exception {
  AdminApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AdminApi {
  AdminApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AdminConfig.apiBaseUrl;

  final http.Client _client;
  final String baseUrl;
  String? token;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final body = await _post('/api/admin/login', {
      'email': email,
      'password': password,
    });
    token = body['token'] as String?;
    return body;
  }

  Future<Map<String, dynamic>> overview() async {
    final body = await _get('/api/admin/overview');
    return body['overview'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> catalog() async {
    final body = await _get('/api/admin/catalog');
    return body['catalog'] as Map<String, dynamic>? ?? {};
  }

  Future<List<dynamic>> saveSportsFacePuzzles(List<dynamic> puzzles) async {
    final body = await _put('/api/admin/catalog/sports-face-puzzles', {
      'puzzles': puzzles,
    });
    return body['puzzles'] as List<dynamic>? ?? puzzles;
  }

  Future<List<dynamic>> saveHubCategories(List<dynamic> categories) async {
    final body = await _put('/api/admin/catalog/hub-categories', {
      'categories': categories,
    });
    return body['categories'] as List<dynamic>? ?? categories;
  }

  Future<List<dynamic>> saveNationalTeams(List<dynamic> teams) async {
    final body = await _put('/api/admin/catalog/national-teams', {
      'teams': teams,
    });
    return body['teams'] as List<dynamic>? ?? teams;
  }

  Future<List<dynamic>> saveIplTeams(List<dynamic> teams) async {
    final body = await _put('/api/admin/catalog/ipl-teams', {
      'teams': teams,
    });
    return body['teams'] as List<dynamic>? ?? teams;
  }

  Future<List<dynamic>> saveVenues(List<dynamic> venues) async {
    final body = await _put('/api/admin/catalog/venues', {
      'venues': venues,
    });
    return body['venues'] as List<dynamic>? ?? venues;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client.get(_uri(path), headers: _headers);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } catch (_) {
      body = {'error': response.body};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(
        body['error'] as String? ??
            body['message'] as String? ??
            'Request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return body;
  }
}
