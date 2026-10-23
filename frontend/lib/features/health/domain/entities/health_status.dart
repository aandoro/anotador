class HealthStatus {
  final String status;
  final String projectName;
  final String environment;
  final String version;

  const HealthStatus({
    required this.status,
    required this.projectName,
    required this.environment,
    required this.version,
  });

  bool get isHealthy => status.toLowerCase() == 'ok';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthStatus &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          projectName == other.projectName &&
          environment == other.environment &&
          version == other.version;

  @override
  int get hashCode =>
      status.hashCode ^
      projectName.hashCode ^
      environment.hashCode ^
      version.hashCode;
}
