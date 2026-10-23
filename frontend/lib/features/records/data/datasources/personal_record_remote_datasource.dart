import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/progression_group.dart';
import '../models/personal_record_model.dart';
import '../models/progression_group_model.dart';

abstract class PersonalRecordRemoteDataSource {
  Future<List<PersonalRecord>> fetchUserRecords();
  Future<PersonalRecord> createRecord(PersonalRecord record);
  Future<PersonalRecord> updateRecord(PersonalRecord record);
  Future<void> deleteRecord(String recordId);
  Future<List<ProgressionGroup>> fetchProgressionSummary();
}

class PersonalRecordRemoteDataSourceImpl implements PersonalRecordRemoteDataSource {
  final ApiClient apiClient;

  PersonalRecordRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PersonalRecord>> fetchUserRecords() async {
    final response = await apiClient.get(ApiEndpoints.records);
    if (response is List) {
      return response
          .map((item) => PersonalRecordModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) async {
    final response = await apiClient.post(
      ApiEndpoints.records,
      body: PersonalRecordModel.fromEntity(record).toJson(),
    );
    if (response is Map<String, dynamic>) {
      return PersonalRecordModel.fromJson(response);
    }
    throw ApiException('Respuesta inesperada al crear el récord personal');
  }

  @override
  Future<PersonalRecord> updateRecord(PersonalRecord record) async {
    final response = await apiClient.put(
      '${ApiEndpoints.records}/${record.id}',
      body: PersonalRecordModel.fromEntity(record).toJson(),
    );
    if (response is Map<String, dynamic>) {
      return PersonalRecordModel.fromJson(response);
    }
    throw ApiException('Respuesta inesperada al actualizar el récord personal');
  }

  @override
  Future<void> deleteRecord(String recordId) async {
    await apiClient.delete('${ApiEndpoints.records}/$recordId');
  }

  @override
  Future<List<ProgressionGroup>> fetchProgressionSummary() async {
    final response = await apiClient.get(ApiEndpoints.recordsProgression);
    if (response is List) {
      return response
          .map((item) => ProgressionGroupModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
