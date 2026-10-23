import '../../domain/entities/health_status.dart';

class HealthStatusModel extends HealthStatus {
  const HealthStatusModel({
    required super.status,
    required super.projectName,
    required super.environment,
    required super.version,
  });

  factory HealthStatusModel.fromJson(Map<String, dynamic> json) {
    return HealthStatusModel(
      status: json['status'] as String? ?? 'unknown',
      projectName: json['project_name'] as String? ?? 'Mio API',
      environment: json['environment'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '0.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'project_name': projectName,
      'environment': environment,
      'version': version,
    };
  }
}
