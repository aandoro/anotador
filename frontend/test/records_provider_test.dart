import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/core/utils/date_format_utils.dart';
import 'package:mio_app/core/utils/measurement_format_utils.dart';
import 'package:mio_app/core/utils/exercise_ui_helper.dart';
import 'package:mio_app/features/records/data/datasources/exercise_remote_datasource.dart';
import 'package:mio_app/features/records/data/datasources/personal_record_remote_datasource.dart';
import 'package:mio_app/features/records/data/models/personal_record_model.dart';
import 'package:mio_app/features/records/data/models/progression_group_model.dart';
import 'package:mio_app/features/records/domain/entities/exercise.dart';
import 'package:mio_app/features/records/domain/entities/personal_record.dart';
import 'package:mio_app/features/records/domain/entities/progression_group.dart';
import 'package:mio_app/features/records/presentation/providers/records_provider.dart';

class FakeExerciseRemoteDataSource implements ExerciseRemoteDataSource {
  int callsCount = 0;
  String lastQuery = '';

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    callsCount++;
    lastQuery = query;
    if (query.toLowerCase().contains('sentad')) {
      return const [
        Exercise(id: 'ex-1', name: 'Sentadilla Trasera'),
        Exercise(id: 'ex-2', name: 'Sentadilla Frontal'),
      ];
    }
    return [];
  }
}

class FakePersonalRecordRemoteDataSource implements PersonalRecordRemoteDataSource {
  int fetchCallsCount = 0;
  int fetchProgressionCallsCount = 0;
  int createCallsCount = 0;
  int updateCallsCount = 0;
  int deleteCallsCount = 0;
  bool shouldThrow = false;

  final List<PersonalRecord> remoteRecords = [
    PersonalRecord(
      id: 'pr-remote-1',
      exerciseName: 'Sentadilla Trasera',
      weightKg: 140,
      reps: 1,
      date: DateTime(2026, 9, 12),
    ),
  ];

  final List<ProgressionGroup> remoteProgressions = [
    ProgressionGroup(
      exerciseName: 'Sentadilla Trasera',
      reps: 1,
      currentPrWeight: 140,
      history: [
        ProgressionPoint(date: DateTime(2026, 9, 12), weightKg: 140),
      ],
    ),
  ];

  @override
  Future<List<PersonalRecord>> fetchUserRecords() async {
    fetchCallsCount++;
    if (shouldThrow) throw Exception('Error de conexión con el backend');
    return List.from(remoteRecords);
  }

  @override
  Future<List<ProgressionGroup>> fetchProgressionSummary() async {
    fetchProgressionCallsCount++;
    if (shouldThrow) throw Exception('Error al cargar progresiones');
    return List.from(remoteProgressions);
  }

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) async {
    createCallsCount++;
    if (shouldThrow) throw Exception('Error al guardar en el backend');
    final created = PersonalRecord(
      id: 'pr-created-123',
      exerciseName: record.exerciseName,
      exerciseId: record.exerciseId,
      weightKg: record.weightKg,
      reps: record.reps,
      date: record.date,
      notes: record.notes,
    );
    remoteRecords.insert(0, created);
    return created;
  }

  @override
  Future<PersonalRecord> updateRecord(PersonalRecord record) async {
    updateCallsCount++;
    if (shouldThrow) throw Exception('Error al actualizar en el backend');
    final index = remoteRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      remoteRecords[index] = record;
      return record;
    }
    throw Exception('No encontrado');
  }

  @override
  Future<void> deleteRecord(String recordId) async {
    deleteCallsCount++;
    if (shouldThrow) throw Exception('Error al eliminar en el backend');
    remoteRecords.removeWhere((r) => r.id == recordId);
  }
}

void main() {
  group('PersonalRecord Entity Tests', () {
    test('formatea repsDisplay y weightDisplay correctamente sin 1RM', () {
      final pr1 = PersonalRecord(
        id: '1',
        exerciseName: 'Press de Banca',
        weightKg: 100,
        reps: 1,
        date: DateTime(2026, 10, 4),
      );

      expect(pr1.weightDisplay, '100 kg');
      expect(pr1.repsDisplay, '1 rep');
      expect(pr1.repsDisplay.contains('(1RM)'), isFalse);
      expect(pr1.formattedDate, '04 Oct 2026');

      final pr3 = PersonalRecord(
        id: '2',
        exerciseName: 'Press Militar',
        weightKg: 62.5,
        reps: 3,
        date: DateTime(2026, 8, 15),
      );

      expect(pr3.weightDisplay, '62.5 kg');
      expect(pr3.repsDisplay, '3 reps');
    });

    test('serializa y deserializa JSON correctamente usando PersonalRecordModel', () {
      final json = {
        'id': 'pr-99',
        'exercise_name': 'Peso Muerto',
        'exercise_id': 'ex-005',
        'weight_kg': 180.5,
        'reps': 2,
        'record_date': '2026-09-20',
        'notes': 'Nueva marca personal',
      };

      final pr = PersonalRecordModel.fromJson(json);
      expect(pr.id, 'pr-99');
      expect(pr.exerciseName, 'Peso Muerto');
      expect(pr.weightKg, 180.5);
      expect(pr.reps, 2);
      expect(pr.notes, 'Nueva marca personal');

      final serialized = pr.toJson();
      expect(serialized['exercise_name'], 'Peso Muerto');
      expect(serialized['weight_kg'], 180.5);
      expect(serialized['reps'], 2);
      expect(serialized['record_date'], '2026-09-20');
      expect(serialized['notes'], 'Nueva marca personal');
    });
  });

  group('ProgressionGroup Model & Entity Tests', () {
    test('parsea JSON correctamente y calcula deltaDisplay', () {
      final json = {
        'exercise_name': 'Press de Banca',
        'reps': 5,
        'current_pr_weight': 85.0,
        'previous_weight': 80.0,
        'delta_kg': 5.0,
        'history': [
          {'record_date': '2026-09-01', 'weight_kg': 80.0},
          {'record_date': '2026-09-15', 'weight_kg': 85.0},
        ],
      };

      final group = ProgressionGroupModel.fromJson(json);
      expect(group.exerciseName, 'Press de Banca');
      expect(group.reps, 5);
      expect(group.currentPrWeight, 85.0);
      expect(group.weightDisplay, '85 kg');
      expect(group.deltaDisplay, '+5 kg');
      expect(group.history.length, 2);
      expect(group.history.first.weightDisplay, '80 kg');
    });

    test('deltaDisplay es null cuando deltaKg no está presente', () {
      final group = ProgressionGroup(
        exerciseName: 'Sentadilla',
        reps: 1,
        currentPrWeight: 150.0,
        history: [ProgressionPoint(date: DateTime.now(), weightKg: 150.0)],
      );

      expect(group.deltaDisplay, isNull);
    });
  });

  group('Core Utils & UI Helpers Tests', () {
    test('DateFormatUtils formatea fechas en distintos formatos', () {
      final date = DateTime(2026, 10, 9);
      expect(DateFormatUtils.formatFullDate(date), '09 Oct 2026');
      expect(DateFormatUtils.formatShortDate(date), '09 Oct');
      expect(DateFormatUtils.formatIsoDate(date), '2026-10-09');
    });

    test('MeasurementFormatUtils formatea peso, repeticiones y deltas', () {
      expect(MeasurementFormatUtils.formatWeight(100.0), '100 kg');
      expect(MeasurementFormatUtils.formatWeight(82.5), '82.5 kg');
      expect(MeasurementFormatUtils.formatReps(1), '1 rep');
      expect(MeasurementFormatUtils.formatReps(5), '5 reps');
      expect(MeasurementFormatUtils.formatDelta(5.0), '+5 kg');
      expect(MeasurementFormatUtils.formatDelta(-2.5), '-2.5 kg');
      expect(MeasurementFormatUtils.formatDelta(0.0), '= Mismo peso');
      expect(MeasurementFormatUtils.formatDelta(null), isNull);
    });

    test('ExerciseUiHelper resuelve iconos según nombre de movimiento', () {
      expect(ExerciseUiHelper.getIconForExercise('Press de Banca').codePoint, isNotNull);
      expect(ExerciseUiHelper.getIconForExercise('Dominadas').codePoint, isNotNull);
      expect(ExerciseUiHelper.getIconForExercise('Sentadilla').codePoint, isNotNull);
    });
  });

  group('RecordsProvider Unit Tests', () {
    late FakeExerciseRemoteDataSource fakeExerciseDataSource;
    late FakePersonalRecordRemoteDataSource fakeRecordDataSource;
    late RecordsProvider provider;

    setUp(() {
      fakeExerciseDataSource = FakeExerciseRemoteDataSource();
      fakeRecordDataSource = FakePersonalRecordRemoteDataSource();
      provider = RecordsProvider(
        exerciseDataSource: fakeExerciseDataSource,
        recordDataSource: fakeRecordDataSource,
      );
    });

    test('inicializa con lista vacía por defecto y sin error', () {
      expect(provider.records, isEmpty);
      expect(provider.progressionGroups, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('loadRecords obtiene los PRs y progresiones del backend exitosamente', () async {
      await provider.loadRecords();

      expect(provider.isLoading, isFalse);
      expect(provider.records.length, 1);
      expect(provider.records.first.exerciseName, 'Sentadilla Trasera');
      expect(provider.progressionGroups.length, 1);
      expect(provider.progressionGroups.first.exerciseName, 'Sentadilla Trasera');
      expect(fakeRecordDataSource.fetchCallsCount, 1);
      expect(fakeRecordDataSource.fetchProgressionCallsCount, 1);
    });

    test('loadRecords captura mensaje de error cuando el backend falla', () async {
      fakeRecordDataSource.shouldThrow = true;

      await provider.loadRecords();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Error de conexión'));
      expect(provider.records, isEmpty);
      expect(provider.progressionGroups, isEmpty);
    });

    test('addRecord persiste el nuevo PR y actualiza la lista', () async {
      final newRecord = PersonalRecord(
        id: '',
        exerciseName: 'Hip Thrust',
        weightKg: 180,
        reps: 5,
        date: DateTime.now(),
      );

      final success = await provider.addRecord(newRecord);

      expect(success, isTrue);
      expect(fakeRecordDataSource.createCallsCount, 1);
      expect(provider.records.length, 1);
      expect(provider.records.first.exerciseName, 'Hip Thrust');
      expect(provider.records.first.id, 'pr-created-123');
    });

    test('recálculo local agrupa PRs del mismo ejercicio y reps calculando el incremento de peso', () async {
      final localProvider = RecordsProvider(
        exerciseDataSource: fakeExerciseDataSource,
        initialRecords: [
          PersonalRecord(
            id: '1',
            exerciseName: 'Press Militar',
            weightKg: 50.0,
            reps: 5,
            date: DateTime(2026, 8, 1),
          ),
          PersonalRecord(
            id: '2',
            exerciseName: 'Press Militar',
            weightKg: 55.0,
            reps: 5,
            date: DateTime(2026, 8, 15),
          ),
        ],
      );

      expect(localProvider.progressionGroups.length, 1);
      final group = localProvider.progressionGroups.first;
      expect(group.exerciseName, 'Press Militar');
      expect(group.reps, 5);
      expect(group.currentPrWeight, 55.0);
      expect(group.previousWeight, 50.0);
      expect(group.deltaKg, 5.0);
      expect(group.deltaDisplay, '+5 kg');
      expect(group.history.length, 2);
    });

    test('addRecord retorna false y registra errorMessage si el backend falla', () async {
      fakeRecordDataSource.shouldThrow = true;

      final newRecord = PersonalRecord(
        id: '',
        exerciseName: 'Hip Thrust',
        weightKg: 180,
        reps: 5,
        date: DateTime.now(),
      );

      final success = await provider.addRecord(newRecord);

      expect(success, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.records, isEmpty);
    });

    test('updateRecord actualiza el PR y recálculo de progresiones exitosamente', () async {
      await provider.loadRecords();
      expect(provider.records.length, 1);

      final toUpdate = PersonalRecord(
        id: 'pr-remote-1',
        exerciseName: 'Sentadilla Trasera',
        weightKg: 145.0,
        reps: 1,
        date: DateTime(2026, 9, 12),
      );

      final success = await provider.updateRecord(toUpdate);
      expect(success, isTrue);
      expect(fakeRecordDataSource.updateCallsCount, 1);
      expect(provider.records.first.weightKg, 145.0);
    });

    test('deleteRecord elimina el PR de la lista local exitosamente', () async {
      await provider.loadRecords();
      expect(provider.records.length, 1);

      final success = await provider.deleteRecord('pr-remote-1');
      expect(success, isTrue);
      expect(fakeRecordDataSource.deleteCallsCount, 1);
      expect(provider.records, isEmpty);
    });

    test('updateRecord y deleteRecord capturan error cuando el backend falla', () async {
      await provider.loadRecords();
      fakeRecordDataSource.shouldThrow = true;

      final updateSuccess = await provider.updateRecord(provider.records.first);
      expect(updateSuccess, isFalse);
      expect(provider.errorMessage, isNotNull);

      final deleteSuccess = await provider.deleteRecord('pr-remote-1');
      expect(deleteSuccess, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('searchExercises con menos de 3 caracteres no llama al datasource', () async {
      final results = await provider.searchExercises('se');

      expect(results, isEmpty);
      expect(fakeExerciseDataSource.callsCount, 0);
    });

    test('searchExercises con 3 o más caracteres consulta y retorna resultados', () async {
      final results = await provider.searchExercises('sentad');

      expect(results.length, 2);
      expect(results.first.name, 'Sentadilla Trasera');
      expect(fakeExerciseDataSource.callsCount, 1);
      expect(fakeExerciseDataSource.lastQuery, 'sentad');
    });
  });
}
