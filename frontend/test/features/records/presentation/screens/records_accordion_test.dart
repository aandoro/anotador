import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/features/records/data/datasources/exercise_remote_datasource.dart';
import 'package:mio_app/features/records/data/datasources/personal_record_remote_datasource.dart';
import 'package:mio_app/features/records/domain/entities/exercise.dart';
import 'package:mio_app/features/records/domain/entities/personal_record.dart';
import 'package:mio_app/features/records/domain/entities/progression_group.dart';
import 'package:mio_app/features/records/presentation/providers/records_provider.dart';
import 'package:mio_app/features/records/presentation/screens/records_screen.dart';
import 'package:provider/provider.dart';

class MockExerciseDataSource implements ExerciseRemoteDataSource {
  @override
  Future<List<Exercise>> searchExercises(String query) async => [];
}

class MockPersonalRecordDataSource implements PersonalRecordRemoteDataSource {
  final List<ProgressionGroup> mockProgressions;

  MockPersonalRecordDataSource(this.mockProgressions);

  @override
  Future<List<PersonalRecord>> fetchUserRecords() async => [];

  @override
  Future<List<ProgressionGroup>> fetchProgressionSummary() async => mockProgressions;

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) async => record;

  @override
  Future<PersonalRecord> updateRecord(PersonalRecord record) async => record;

  @override
  Future<void> deleteRecord(String recordId) async {}
}

void main() {
  testWidgets('RecordsScreen inicia con todas las cards cerradas y aplica acordeón exclusivo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final progressions = [
      ProgressionGroup(
        exerciseName: 'Sentadilla Trasera',
        reps: 1,
        currentPrWeight: 140.0,
        history: [ProgressionPoint(date: DateTime(2026, 9, 1), weightKg: 140.0)],
      ),
      ProgressionGroup(
        exerciseName: 'Press de Banca',
        reps: 1,
        currentPrWeight: 100.0,
        history: [ProgressionPoint(date: DateTime(2026, 9, 1), weightKg: 100.0)],
      ),
    ];

    final provider = RecordsProvider(
      exerciseDataSource: MockExerciseDataSource(),
      recordDataSource: MockPersonalRecordDataSource(progressions),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: RecordsScreen(),
        ),
      ),
    );

    // Cargar datos
    await tester.pumpAndSettle();

    // Ambas cards deben estar renderizadas
    expect(find.text('Sentadilla Trasera'), findsOneWidget);
    expect(find.text('Press de Banca'), findsOneWidget);

    // Inicialmente todas las cards inician cerradas (flechas abajo, sin curvas)
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(2));
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    expect(find.text('Curva de Evolución'), findsNothing);

    // Abrir Card 1: Sentadilla Trasera
    await tester.tap(find.text('Sentadilla Trasera'));
    await tester.pumpAndSettle();

    // Solo Card 1 expandida
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.text('Récord a 1 rep'), findsOneWidget);
    expect(find.text('140 kg'), findsOneWidget);

    // Abrir Card 2: Press de Banca -> Card 1 debe cerrarse automáticamente
    await tester.tap(find.text('Press de Banca'));
    await tester.pumpAndSettle();

    // Solo Card 2 expandida
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.text('Récord a 1 rep'), findsOneWidget);
    expect(find.text('100 kg'), findsOneWidget);
    expect(find.text('140 kg'), findsNothing);

    // Tocar Card 2 de nuevo -> debe cerrarse
    await tester.tap(find.text('Press de Banca'));
    await tester.pumpAndSettle();

    // Ambas cards cerradas nuevamente
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(2));
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
  });
}
