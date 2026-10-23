import '../../../../core/network/api_client.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final ApiClient apiClient;

  AuthRepository({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.apiClient,
  });

  Future<UserModel> login(String email, String password) async {
    final data = await remoteDataSource.login(email, password);
    final token = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    apiClient.setAuthToken(token);
    await localDataSource.saveSession(
      token: token,
      refreshToken: refreshToken,
      user: user,
    );
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final data = await remoteDataSource.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role,
    );
    final token = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    apiClient.setAuthToken(token);
    await localDataSource.saveSession(
      token: token,
      refreshToken: refreshToken,
      user: user,
    );
    return user;
  }

  Future<UserModel?> restoreSession() async {
    final token = await localDataSource.getToken();
    final refreshToken = await localDataSource.getRefreshToken();

    if (token == null || token.isEmpty) {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        return await _attemptRefresh(refreshToken);
      }
      return null;
    }

    apiClient.setAuthToken(token);
    try {
      final user = await remoteDataSource.getProfile();
      await localDataSource.saveSession(
        token: token,
        refreshToken: refreshToken,
        user: user,
      );
      return user;
    } catch (_) {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        return await _attemptRefresh(refreshToken);
      }
      await logout();
      return null;
    }
  }

  Future<UserModel?> _attemptRefresh(String refreshToken) async {
    try {
      final data = await remoteDataSource.refreshToken(refreshToken);
      final newToken = data['access_token'] as String;
      final newRefreshToken = (data['refresh_token'] as String?) ?? refreshToken;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      apiClient.setAuthToken(newToken);
      await localDataSource.saveSession(
        token: newToken,
        refreshToken: newRefreshToken,
        user: user,
      );
      return user;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final updatedUser = await remoteDataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
    );
    final token = await localDataSource.getToken();
    final refreshToken = await localDataSource.getRefreshToken();
    if (token != null) {
      await localDataSource.saveSession(
        token: token,
        refreshToken: refreshToken,
        user: updatedUser,
      );
    }
    return updatedUser;
  }

  Future<UserModel> uploadAvatarBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    final updatedUser = await remoteDataSource.uploadAvatarBytes(
      bytes: bytes,
      filename: filename,
    );
    final token = await localDataSource.getToken();
    final refreshToken = await localDataSource.getRefreshToken();
    if (token != null) {
      await localDataSource.saveSession(
        token: token,
        refreshToken: refreshToken,
        user: updatedUser,
      );
    }
    return updatedUser;
  }

  Future<void> logout() async {
    await localDataSource.clearSession();
    apiClient.setAuthToken(null);
  }

  Future<String> forgotPassword(String email) async {
    return await remoteDataSource.forgotPassword(email);
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await remoteDataSource.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }
}