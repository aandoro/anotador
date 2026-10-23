import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/exercise.dart';

abstract class ExerciseRemoteDataSource {
  Future<List<Exercise>> searchExercises(String query);
}

class ExerciseRemoteDataSourceImpl implements ExerciseRemoteDataSource {
  final ApiClient apiClient;

  ExerciseRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    final clean = query.trim();
    if (clean.length < 3) return [];

    final url = '${ApiEndpoints.exercises}?search=${Uri.encodeQueryComponent(clean)}';
    final response = await apiClient.get(url);

    if (response is List) {
      return response
          .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
