import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/features/health/data/models/health_status_model.dart';
import 'package:mio_app/features/health/domain/entities/health_status.dart';

void main() {
  group('HealthStatusModel Unit Tests', () {
    test('should parse valid JSON into HealthStatusModel correctly', () {
      final jsonMap = {
        'status': 'ok',
        'project_name': 'Mio API',
        'environment': 'development',
        'version': '0.1.0',
      };

      final model = HealthStatusModel.fromJson(jsonMap);

      expect(model.status, equals('ok'));
      expect(model.projectName, equals('Mio API'));
      expect(model.environment, equals('development'));
      expect(model.version, equals('0.1.0'));
      expect(model.isHealthy, isTrue);
    });

    test('should convert HealthStatusModel to JSON map correctly', () {
      const model = HealthStatusModel(
        status: 'ok',
        projectName: 'Mio API',
        environment: 'development',
        version: '0.1.0',
      );

      final jsonMap = model.toJson();

      expect(jsonMap['status'], equals('ok'));
      expect(jsonMap['project_name'], equals('Mio API'));
      expect(jsonMap['environment'], equals('development'));
      expect(jsonMap['version'], equals('0.1.0'));
    });

    test('should support value equality on domain entity', () {
      const entity1 = HealthStatus(
        status: 'ok',
        projectName: 'Mio API',
        environment: 'development',
        version: '0.1.0',
      );
      const entity2 = HealthStatus(
        status: 'ok',
        projectName: 'Mio API',
        environment: 'development',
        version: '0.1.0',
      );

      expect(entity1, equals(entity2));
    });
  });
}
