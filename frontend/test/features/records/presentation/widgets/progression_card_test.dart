import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_app/features/records/domain/entities/progression_group.dart';
import 'package:mio_app/features/records/presentation/widgets/one_rep_max_modal.dart';
import 'package:mio_app/features/records/presentation/widgets/progression_card.dart';

void main() {
  final group1RM = ProgressionGroup(
    exerciseName: 'Sentadilla Trasera',
    reps: 1,
    currentPrWeight: 140.0,
    previousWeight: 135.0,
    deltaKg: 5.0,
    history: [
      ProgressionPoint(date: DateTime(2026, 9, 1), weightKg: 135.0),
      ProgressionPoint(date: DateTime(2026, 9, 15), weightKg: 140.0),
    ],
  );

  final group5Reps = ProgressionGroup(
    exerciseName: 'Sentadilla Trasera',
    reps: 5,
    currentPrWeight: 120.0,
    history: [
      ProgressionPoint(date: DateTime(2026, 9, 10), weightKg: 120.0),
    ],
  );

  group('ProgressionCard Widget Tests', () {
    testWidgets('cuando isExpanded es false, no muestra el cuerpo ni el botón 1RM', (tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressionCard(
              exerciseName: 'Sentadilla Trasera',
              groupsForExercise: [group1RM],
              isExpanded: false,
              onToggleExpand: () {
                toggleCalled = true;
              },
            ),
          ),
        ),
      );

      // Cabecera presente
      expect(find.text('Sentadilla Trasera'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);

      // Cuerpo oculto
      expect(find.text('Curva de Evolución'), findsNothing);
      expect(find.byKey(const Key('one_rep_max_button')), findsNothing);

      // Al pulsar en la cabecera se invoca onToggleExpand
      await tester.tap(find.text('Sentadilla Trasera'));
      await tester.pump();
      expect(toggleCalled, isTrue);
    });

    testWidgets('cuando isExpanded es true y reps == 1, muestra botón 1RM y gráfico', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressionCard(
              exerciseName: 'Sentadilla Trasera',
              groupsForExercise: [group1RM],
              isExpanded: true,
              onToggleExpand: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('Curva de Evolución'), findsOneWidget);
      expect(find.byKey(const Key('one_rep_max_button')), findsOneWidget);
      expect(find.text('Ver Tabla de Porcentajes (1RM)'), findsOneWidget);
    });

    testWidgets('cuando isExpanded es true y reps > 1, NO muestra botón 1RM', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressionCard(
              exerciseName: 'Sentadilla Trasera',
              groupsForExercise: [group5Reps],
              isExpanded: true,
              onToggleExpand: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('Curva de Evolución'), findsOneWidget);
      expect(find.byKey(const Key('one_rep_max_button')), findsNothing);
      expect(find.text('Ver Tabla de Porcentajes (1RM)'), findsNothing);
    });
  });

  group('OneRepMaxModal Widget Tests', () {
    testWidgets('renderiza tabla de porcentajes del 100% al 10% con cálculos exactos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  OneRepMaxModal.show(
                    context,
                    exerciseName: 'Sentadilla Trasera',
                    oneRepMaxWeight: 100.0,
                  );
                },
                child: const Text('Abrir Modal'),
              ),
            ),
          ),
        ),
      );

      // Abrir modal
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Verificar cabecera
      expect(find.text('Tabla de Porcentajes (1RM)'), findsOneWidget);
      expect(find.text('Sentadilla Trasera • 100% = 100 kg'), findsOneWidget);

      // Verificar fila del 100%
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('1 rep (1RM)'), findsOneWidget);

      // Verificar selector de granularidad
      expect(find.byKey(const Key('granularity_step_5')), findsOneWidget);
      expect(find.byKey(const Key('granularity_step_10')), findsOneWidget);

      // Cambiar a granularidad de 10%
      await tester.tap(find.byKey(const Key('granularity_step_10')));
      await tester.pumpAndSettle();

      // En cada 10%, 95% ya no debe existir
      expect(find.text('95%'), findsNothing);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('90 kg'), findsOneWidget);

      // Cerrar modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Tabla de Porcentajes (1RM)'), findsNothing);
    });
  });
}
