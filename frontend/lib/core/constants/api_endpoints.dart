class ApiEndpoints {
  ApiEndpoints._();

  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  static const String apiV1Prefix = '/api/v1';

  /// Normaliza la URL base recortando espacios en blanco y barras finales.
  /// Si la URL resultante es vacía, recurre a [defaultBaseUrl].
  static String normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1).trim();
    }
    return trimmed.isEmpty ? defaultBaseUrl : trimmed;
  }

  /// URL base configurada desde variables de compilación (--dart-define=API_BASE_URL=...)
  static final String baseUrl = normalizeBaseUrl(
    const String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl),
  );

  // Endpoints V1 (Retrocompatibles)
  static String get health => '$baseUrl$apiV1Prefix/health';
  static String get register => '$baseUrl$apiV1Prefix/auth/register';
  static String get login => '$baseUrl$apiV1Prefix/auth/login';
  static String get refresh => '$baseUrl$apiV1Prefix/auth/refresh';
  static String get forgotPassword => '$baseUrl$apiV1Prefix/auth/forgot-password';
  static String get resetPassword => '$baseUrl$apiV1Prefix/auth/reset-password';
  static String get me => '$baseUrl$apiV1Prefix/users/me';
  static String get avatar => '$baseUrl$apiV1Prefix/users/me/avatar';
  static String get exercises => '$baseUrl$apiV1Prefix/exercises';
  static String get records => '$baseUrl$apiV1Prefix/records';
  static String get recordsProgression => '$baseUrl$apiV1Prefix/records/progression';
}