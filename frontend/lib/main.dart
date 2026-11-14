import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/records/data/datasources/exercise_remote_datasource.dart';
import 'features/records/data/datasources/personal_record_remote_datasource.dart';
import 'features/records/presentation/providers/records_provider.dart';
import 'core/layout/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authRepository = AuthRepository(
    remoteDataSource: AuthRemoteDataSourceImpl(apiClient: apiClient),
    localDataSource: AuthLocalDataSourceImpl(),
    apiClient: apiClient,
  );
  final exerciseDataSource = ExerciseRemoteDataSourceImpl(apiClient: apiClient);
  final personalRecordDataSource = PersonalRecordRemoteDataSourceImpl(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordsProvider(
            exerciseDataSource: exerciseDataSource,
            recordDataSource: personalRecordDataSource,
          ),
        ),
      ],
      child: const MioApp(),
    ),
  );
}

class MioApp extends StatelessWidget {
  const MioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mio App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const AuthWrapper(),
        '/dashboard': (_) => const AuthWrapper(),
        '/records': (_) => const AuthWrapper(),
        '/profile': (_) => const AuthWrapper(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.status == AuthStatus.initial) {
        auth.checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    if (status == AuthStatus.initial || status == AuthStatus.authenticating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Iniciando WODBook...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (status == AuthStatus.authenticated) {
      return const AppShell();
    }

    return const LoginScreen();
  }
}