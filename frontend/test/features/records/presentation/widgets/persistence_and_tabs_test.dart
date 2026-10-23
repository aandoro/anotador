import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/core/constants/app_colors.dart';
import 'package:mio_app/core/theme/app_theme.dart';
import 'package:mio_app/features/records/data/datasources/exercise_remote_datasource.dart';
import 'package:mio_app/features/records/data/datasources/personal_record_remote_datasource.dart';
import 'package:mio_app/features/records/domain/entities/exercise.dart';
import 'package:mio_app/features/records/domain/entities/personal_record.dart';
import 'package:mio_app/features/records/domain/entities/progression_group.dart';
import 'package:mio_app/features/records/presentation/providers/records_provider.dart';
import 'package:mio_app/features/records/presentation/screens/records_screen.dart';
import 'package:mio_app/features/records/presentation/widgets/add_record_modal.dart';
import 'package:provider/provider.dart';

class DelayedExerciseDataSource implements ExerciseRemoteDataSource {
  @override
  Future<List<Exercise>> searchExercises(String query) async => [
        const Exercise(id: 'ex-1', name: 'Sentadilla Trasera'),
      ];
}

class DelayedPersonalRecordDataSource implements PersonalRecordRemoteDataSource {
  Completer<PersonalRecord>? createCompleter;
  Completer<PersonalRecord>? updateCompleter;
  Completer<void>? deleteCompleter;
  List<PersonalRecord> initialRecords;

  DelayedPersonalRecordDataSource({this.initialRecords = const []});

  @override
  Future<List<PersonalRecord>> fetchUserRecords() async => initialRecords;

  @override
  Future<List<ProgressionGroup>> fetchProgressionSummary() async => [];

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) {
    createCompleter = Completer<PersonalRecord>();
    return createCompleter!.future;
  }

  @override
  Future<PersonalRecord> updateRecord(PersonalRecord record) {
    updateCompleter = Completer<PersonalRecord>();
    return updateCompleter!.future;
  }

  @override
  Future<void> deleteRecord(String recordId) {
    deleteCompleter = Completer<void>();
    return deleteCompleter!.future;
  }
}

void main() {
  group('Persistencia con Spinner y Bloqueo de Interacción', () {
    testWidgets('AddRecordModal muestra spinner y bloquea botones mientras persiste', (tester) async {
      final delayedDataSource = DelayedPersonalRecordDataSource();
      final provider = RecordsProvider(
        exerciseDataSource: DelayedExerciseDataSource(),
        recordDataSource: delayedDataSource,
      );

      final existingRecord = PersonalRecord(
        id: 'pr-1',
        exerciseName: 'Sentadilla Trasera',
        exerciseId: 'ex-1',
        weightKg: 140.0,
        reps: 1,
        date: DateTime(2026, 10, 1),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AddRecordModal(recordToEdit: existingRecord),
            ),
          ),
        ),
      );

      // Inicialmente el botón muestra "Guardar Cambios" y no hay spinner
      expect(find.text('Guardar Cambios'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Pulsar "Guardar Cambios"
      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      // El provider debe estar en isActionLoading == true
      expect(provider.isActionLoading, isTrue);

      // El botón debe mostrar el CircularProgressIndicator y estar deshabilitado
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNull);

      // El botón de cerrar (X) debe estar deshabilitado
      final closeIconBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close));
      expect(closeIconBtn.onPressed, isNull);

      // Completar la petición asíncrona
      delayedDataSource.updateCompleter!.complete(existingRecord);
      await tester.pumpAndSettle();

      expect(provider.isActionLoading, isFalse);
    });

    testWidgets('Diálogo de eliminar en RecordsScreen muestra spinner y bloquea botones durante borrado', (tester) async {
      final existingRecord = PersonalRecord(
        id: 'pr-1',
        exerciseName: 'Sentadilla Trasera',
        exerciseId: 'ex-1',
        weightKg: 140.0,
        reps: 1,
        date: DateTime(2026, 10, 1),
      );
      final delayedDataSource = DelayedPersonalRecordDataSource(
        initialRecords: [existingRecord],
      );
      final provider = RecordsProvider(
        exerciseDataSource: DelayedExerciseDataSource(),
        recordDataSource: delayedDataSource,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RecordsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ir a la pestaña Historial
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      // Abrir menú de opciones del registro y pulsar Eliminar
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Se abre el AlertDialog de confirmación
      expect(find.text('Eliminar Récord Personal'), findsOneWidget);

      // Pulsar el botón "Eliminar" del diálogo
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Eliminar');
      await tester.tap(deleteBtnFinder);
      await tester.pump();

      // Mientras se elimina, debe aparecer el spinner y bloquearse Cancelar y Eliminar
      expect(provider.isActionLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final cancelBtn = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'));
      expect(cancelBtn.onPressed, isNull);

      // Completar eliminación
      delayedDataSource.deleteCompleter!.complete();
      await tester.pumpAndSettle();

      expect(provider.isActionLoading, isFalse);
      expect(find.text('Eliminar Récord Personal'), findsNothing);
    });
  });

  group('Estilización de Tabs (surface y background)', () {
    testWidgets('TabBar en RecordsScreen usa AppColors.surface para seleccionada y AppColors.background para no seleccionada', (tester) async {
      final provider = RecordsProvider(
        exerciseDataSource: DelayedExerciseDataSource(),
        recordDataSource: DelayedPersonalRecordDataSource(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RecordsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.labelColor, equals(AppColors.surface));
      expect(tabBar.indicatorColor, equals(AppColors.surface));
      expect(tabBar.unselectedLabelColor, equals(AppColors.background.withValues(alpha: 0.72)));
      expect(tabBar.unselectedLabelColor, isNot(equals(AppColors.textSecondary)));
    });
  });
}
