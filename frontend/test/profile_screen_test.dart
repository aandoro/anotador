import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mio_app/core/network/api_client.dart';
import 'package:mio_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mio_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mio_app/features/auth/data/models/user_model.dart';
import 'package:mio_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mio_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:mio_app/features/profile/presentation/screens/profile_screen.dart';

class FakeAuthRepository implements AuthRepository {
  final UserModel user;

  FakeAuthRepository(this.user);

  @override
  late final AuthRemoteDataSource remoteDataSource;
  @override
  late final AuthLocalDataSource localDataSource;
  @override
  late final ApiClient apiClient;

  @override
  Future<UserModel?> restoreSession() async => user;

  @override
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    return user.copyWith(firstName: firstName, lastName: lastName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const initialUser = UserModel(
    id: 'user-123',
    email: 'carlos@mio.app',
    firstName: 'Carlos',
    lastName: 'Gómez',
    role: 'trainer',
  );

  Widget createWidgetUnderTest(AuthProvider authProvider) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const ProfileScreen(),
      ),
    );
  }

  testWidgets(
      'El botón Guardar Cambios está deshabilitado si no hay cambios y se habilita al editar',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository(initialUser);
    final authProvider = AuthProvider(repository: fakeRepo);
    await authProvider.checkAuthStatus();

    await tester.pumpWidget(createWidgetUnderTest(authProvider));
    await tester.pumpAndSettle();

    // 1. Verificar estado inicial: Botón 'Guardar Cambios' debe estar deshabilitado
    final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Guardar Cambios');
    expect(saveButtonFinder, findsOneWidget);

    ElevatedButton saveButton = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNull,
        reason: 'El botón debe estar deshabilitado inicialmente al no haber cambios');

    // 2. Modificar el nombre
    final firstNameFinder = find.widgetWithText(TextFormField, 'Nombre');
    await tester.enterText(firstNameFinder, 'Carlos Modificado');
    await tester.pump();

    saveButton = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNotNull,
        reason: 'El botón debe habilitarse tras modificar el nombre');

    // 3. Revertir el nombre al original
    await tester.enterText(firstNameFinder, 'Carlos');
    await tester.pump();

    saveButton = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNull,
        reason: 'El botón debe volver a deshabilitarse si el texto vuelve a ser igual al original');

    // 4. Si el campo se vacía (solo espacios en blanco), el botón debe permanecer deshabilitado
    await tester.enterText(firstNameFinder, '   ');
    await tester.pump();

    saveButton = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNull,
        reason: 'El botón debe permanecer deshabilitado si el campo resultante está vacío');

    // 5. Restaurar nombre y modificar apellido: debe habilitar el botón
    final lastNameFinder = find.widgetWithText(TextFormField, 'Apellido');
    await tester.enterText(firstNameFinder, 'Carlos');
    await tester.enterText(lastNameFinder, 'Pérez');
    await tester.pump();

    saveButton = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNotNull,
        reason: 'El botón debe habilitarse al modificar el apellido');

    // 6. Al presionar Guardar Cambios exitosamente, el botón debe volver a quedar deshabilitado
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    saveButton = tester.widget<ElevatedButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNull,
        reason: 'El botón debe quedar deshabilitado tras guardar exitosamente');
  });
}
