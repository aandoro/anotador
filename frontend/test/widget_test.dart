import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/core/constants/api_endpoints.dart';

void main() {
  group('ApiEndpoints.normalizeBaseUrl', () {
    test('devuelve la URL original si no tiene barras finales', () {
      expect(
        ApiEndpoints.normalizeBaseUrl('https://mio-api.onrender.com'),
        equals('https://mio-api.onrender.com'),
      );
    });

    test('elimina una o múltiples barras finales y espacios circundantes', () {
      expect(
        ApiEndpoints.normalizeBaseUrl('https://mio-api.onrender.com/'),
        equals('https://mio-api.onrender.com'),
      );
      expect(
        ApiEndpoints.normalizeBaseUrl('  https://mio-api.onrender.com///  '),
        equals('https://mio-api.onrender.com'),
      );
    });

    test('retorna defaultBaseUrl si se suministra una cadena vacía o de solo barras', () {
      expect(
        ApiEndpoints.normalizeBaseUrl(''),
        equals(ApiEndpoints.defaultBaseUrl),
      );
      expect(
        ApiEndpoints.normalizeBaseUrl('   '),
        equals(ApiEndpoints.defaultBaseUrl),
      );
      expect(
        ApiEndpoints.normalizeBaseUrl('///'),
        equals(ApiEndpoints.defaultBaseUrl),
      );
    });
  });

  group('ApiEndpoints construction', () {
    test('baseUrl no debe finalizar con barra', () {
      expect(ApiEndpoints.baseUrl.endsWith('/'), isFalse);
    });

    test('los getters de endpoints construyen URLs válidas con prefijo v1', () {
      expect(ApiEndpoints.health, equals('${ApiEndpoints.baseUrl}/api/v1/health'));
      expect(ApiEndpoints.login, equals('${ApiEndpoints.baseUrl}/api/v1/auth/login'));
      expect(ApiEndpoints.refresh, equals('${ApiEndpoints.baseUrl}/api/v1/auth/refresh'));
      expect(ApiEndpoints.register, equals('${ApiEndpoints.baseUrl}/api/v1/auth/register'));
      expect(ApiEndpoints.forgotPassword, equals('${ApiEndpoints.baseUrl}/api/v1/auth/forgot-password'));
      expect(ApiEndpoints.resetPassword, equals('${ApiEndpoints.baseUrl}/api/v1/auth/reset-password'));
      expect(ApiEndpoints.me, equals('${ApiEndpoints.baseUrl}/api/v1/users/me'));
      expect(ApiEndpoints.avatar, equals('${ApiEndpoints.baseUrl}/api/v1/users/me/avatar'));
      expect(ApiEndpoints.exercises, equals('${ApiEndpoints.baseUrl}/api/v1/exercises'));
      expect(ApiEndpoints.records, equals('${ApiEndpoints.baseUrl}/api/v1/records'));
      expect(ApiEndpoints.recordsProgression, equals('${ApiEndpoints.baseUrl}/api/v1/records/progression'));
    });
  });
}
