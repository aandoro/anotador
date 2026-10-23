import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  });
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
  });
  Future<UserModel> uploadAvatarBytes({
    required List<int> bytes,
    required String filename,
  });
  Future<String> forgotPassword(String email);
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      },
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await apiClient.post(
      ApiEndpoints.refresh,
      body: {'refresh_token': refreshToken},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.get(ApiEndpoints.me);
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.me,
      body: {'first_name': firstName, 'last_name': lastName},
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<UserModel> uploadAvatarBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await apiClient.postMultipartBytes(
      url: ApiEndpoints.avatar,
      bytes: bytes,
      filename: filename,
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<String> forgotPassword(String email) async {
    final response = await apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
    );
    final map = response as Map<String, dynamic>;
    return (map['message'] as String?) ?? 'Solicitud procesada con éxito';
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.resetPassword,
      body: {
        'token': token,
        'new_password': newPassword,
      },
    );
    final map = response as Map<String, dynamic>;
    return (map['message'] as String?) ?? 'Contraseña restablecida con éxito';
  }
}