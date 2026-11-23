class AdminConfig {
  /// Same API the player app uses.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:3100',
  );
}
