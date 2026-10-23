import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/core/network/api_client.dart';
import 'package:mio_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mio_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mio_app/features/auth/data/models/user_model.dart';
import 'package:mio_app/features/auth/data/repositories/auth_repository.dart';

class FakeLocalDataSource implements AuthLocalDataSource {
  String? token;
  String? refreshToken;
  UserModel? user;
  bool cleared = false;

  @override
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required UserModel user,
  }) async {
    this.token = token;
    this.refreshToken = refreshToken;
    this.user = user;
    cleared = false;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<UserModel?> getCachedUser() async => user;

  @override
  Future<void> clearSession() async {
    token = null;
    refreshToken = null;
    user = null;
    cleared = true;
  }
}

class FakeRemoteDataSource implements AuthRemoteDataSource {
  bool failProfile = false;
  bool failRefresh = false;
  String? passedRefreshToken;

  @override
  Future<UserModel> getProfile() async {
    if (failProfile) {
      throw Exception('Access token expired (401)');
    }
    return const UserModel(
      id: 'user-1',
      email: 'user@mio.app',
      firstName: 'Test',
      lastName: 'User',
      role: 'trainer',
    );
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    passedRefreshToken = refreshToken;
    if (failRefresh) {
      throw Exception('Refresh token invalid (401)');
    }
    return {
      'access_token': 'new_access_token_xyz',
      'refresh_token': 'new_refresh_token_xyz',
      'user': {
        'id': 'user-1',
        'email': 'user@mio.app',
        'first_name': 'Test',
        'last_name': 'User',
        'role': 'trainer',
        'profile_image_url': null,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> login(String email, String password) async => {};
  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async => {};
  @override
  Future<UserModel> updateProfile({required String firstName, required String lastName}) async =>
      const UserModel(id: '1', email: '', firstName: '', lastName: '', role: '');
  @override
  Future<UserModel> uploadAvatarBytes({required List<int> bytes, required String filename}) async =>
      const UserModel(id: '1', email: '', firstName: '', lastName: '', role: '');
  @override
  Future<String> forgotPassword(String email) async => '';
  @override
  Future<String> resetPassword({required String token, required String newPassword}) async => '';
}

void main() {
  group('AuthRepository.restoreSession with Refresh Token Flow', () {
    late FakeLocalDataSource localDS;
    late FakeRemoteDataSource remoteDS;
    late ApiClient apiClient;
    late AuthRepository repository;

    setUp(() {
      localDS = FakeLocalDataSource();
      remoteDS = FakeRemoteDataSource();
      apiClient = ApiClient();
      repository = AuthRepository(
        remoteDataSource: remoteDS,
        localDataSource: localDS,
        apiClient: apiClient,
      );
    });

    test('retorna el usuario directamente si el access token es válido', () async {
      localDS.token = 'valid_token';
      localDS.refreshToken = 'stored_refresh_token';

      final result = await repository.restoreSession();

      expect(result, isNotNull);
      expect(result!.email, equals('user@mio.app'));
      expect(localDS.token, equals('valid_token'));
      expect(localDS.cleared, isFalse);
    });

    test('refresca sesión exitosamente cuando el access token expiró pero hay refresh token válido', () async {
      localDS.token = 'expired_access_token';
      localDS.refreshToken = 'my_refresh_token';
      remoteDS.failProfile = true; // Simula 401 en getProfile()

      final result = await repository.restoreSession();

      expect(result, isNotNull);
      expect(remoteDS.passedRefreshToken, equals('my_refresh_token'));
      expect(localDS.token, equals('new_access_token_xyz'));
      expect(localDS.refreshToken, equals('new_refresh_token_xyz'));
      expect(localDS.cleared, isFalse);
    });

    test('intenta refrescar si no hay access token pero sí refresh token', () async {
      localDS.token = null;
      localDS.refreshToken = 'only_refresh_token';

      final result = await repository.restoreSession();

      expect(result, isNotNull);
      expect(remoteDS.passedRefreshToken, equals('only_refresh_token'));
      expect(localDS.token, equals('new_access_token_xyz'));
    });

    test('ejecuta logout y retorna null si tanto access token como refresh token fallan', () async {
      localDS.token = 'expired_token';
      localDS.refreshToken = 'invalid_refresh_token';
      remoteDS.failProfile = true;
      remoteDS.failRefresh = true;

      final result = await repository.restoreSession();

      expect(result, isNull);
      expect(localDS.cleared, isTrue);
      expect(localDS.token, isNull);
    });

    test('retorna null sin llamar a refresh si no hay ni token ni refresh token', () async {
      localDS.token = null;
      localDS.refreshToken = null;

      final result = await repository.restoreSession();

      expect(result, isNull);
      expect(remoteDS.passedRefreshToken, isNull);
    });
  });
}
