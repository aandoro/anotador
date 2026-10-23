import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/core/network/api_client.dart';
import 'package:mio_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mio_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mio_app/features/auth/data/models/user_model.dart';
import 'package:mio_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mio_app/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  @override
  late final AuthRemoteDataSource remoteDataSource;
  @override
  late final AuthLocalDataSource localDataSource;
  @override
  late final ApiClient apiClient;

  bool shouldFail = false;

  @override
  Future<String> forgotPassword(String email) async {
    if (shouldFail) throw Exception('No se pudo enviar el correo');
    return 'OK';
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (shouldFail) throw Exception('Código inválido o expirado');
    return 'OK';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserModel Tests', () {
    test('Parsea JSON correctamente a UserModel', () {
      final json = {
        'id': 'uuid-1234',
        'email': 'trainer@mio.app',
        'first_name': 'Juan',
        'last_name': 'Pérez',
        'role': 'trainer',
        'profile_image_url': 'https://example.com/avatar.jpg',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'uuid-1234');
      expect(user.email, 'trainer@mio.app');
      expect(user.firstName, 'Juan');
      expect(user.lastName, 'Pérez');
      expect(user.role, 'trainer');
      expect(user.fullName, 'Juan Pérez');
      expect(user.isAdmin, isFalse);
    });

    test('CopyWith actualiza propiedades sin mutar email ni rol', () {
      const initial = UserModel(
        id: 'uuid-1',
        email: 'trainer@mio.app',
        firstName: 'Juan',
        lastName: 'Pérez',
        role: 'trainer',
      );

      final updated = initial.copyWith(firstName: 'Carlos');

      expect(updated.firstName, 'Carlos');
      expect(updated.email, 'trainer@mio.app');
      expect(updated.id, 'uuid-1');
    });
  });

  group('AuthProvider Forgot and Reset Password Tests', () {
    late MockAuthRepository mockRepo;
    late AuthProvider provider;

    setUp(() {
      mockRepo = MockAuthRepository();
      provider = AuthProvider(repository: mockRepo);
    });

    test('forgotPassword exitoso retorna true y resetea errorMessage', () async {
      mockRepo.shouldFail = false;
      final result = await provider.forgotPassword('user@mio.app');

      expect(result, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isActionLoading, isFalse);
    });

    test('forgotPassword fallido retorna false y captura errorMessage', () async {
      mockRepo.shouldFail = true;
      final result = await provider.forgotPassword('user@mio.app');

      expect(result, isFalse);
      expect(provider.errorMessage, contains('No se pudo enviar el correo'));
      expect(provider.isActionLoading, isFalse);
    });

    test('resetPassword exitoso retorna true y resetea errorMessage', () async {
      mockRepo.shouldFail = false;
      final result = await provider.resetPassword('123456', 'NewPassword123');

      expect(result, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isActionLoading, isFalse);
    });

    test('resetPassword fallido retorna false y captura errorMessage', () async {
      mockRepo.shouldFail = true;
      final result = await provider.resetPassword('bad_token', 'NewPassword123');

      expect(result, isFalse);
      expect(provider.errorMessage, contains('Código inválido o expirado'));
      expect(provider.isActionLoading, isFalse);
    });
  });
}