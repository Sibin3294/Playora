import 'package:flutter/foundation.dart';
import 'package:playora_admin/api/admin_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSession extends ChangeNotifier {
  AdminSession._();
  static final AdminSession instance = AdminSession._();

  static const _tokenKey = 'playora_admin_token';
  static const _emailKey = 'playora_admin_email';

  final api = AdminApi();
  bool bootstrapped = false;
  bool loggedIn = false;
  String? email;
  String? lastError;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final savedEmail = prefs.getString(_emailKey);
    if (token != null && token.isNotEmpty) {
      api.token = token;
      email = savedEmail;
      loggedIn = true;
      try {
        await api.overview();
      } catch (_) {
        await logout(silent: true);
      }
    }
    bootstrapped = true;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    lastError = null;
    try {
      final result = await api.login(email: email, password: password);
      final admin = result['admin'] as Map<String, dynamic>? ?? {};
      this.email = admin['email'] as String? ?? email;
      loggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, api.token ?? '');
      await prefs.setString(_emailKey, this.email ?? '');
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      loggedIn = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout({bool silent = false}) async {
    api.token = null;
    email = null;
    loggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    if (!silent) notifyListeners();
  }
}
