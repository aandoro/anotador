import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/health_status_model.dart';

abstract class HealthRemoteDataSource {
  Future<HealthStatusModel> checkHealth();
  void dispose();
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  final ApiClient apiClient;

  HealthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<HealthStatusModel> checkHealth() async {
    final response = await apiClient.get(ApiEndpoints.health);
    return HealthStatusModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  void dispose() {
    apiClient.close();
  }
}
