import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_status.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  late final HealthRemoteDataSource _dataSource;
  late Future<HealthStatus> _healthFuture;

  @override
  void initState() {
    super.initState();
    _dataSource = HealthRemoteDataSourceImpl(apiClient: ApiClient());
    _loadHealth();
  }

  @override
  void dispose() {
    _dataSource.dispose();
    super.dispose();
  }

  void _loadHealth() {
    setState(() {
      _healthFuture = _dataSource.checkHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mio - Estado del Sistema'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: FutureBuilder<HealthStatus>(
              future: _healthFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Conectando con Backend FastAPI...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error de Conexión',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadHealth,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final health = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              health.isHealthy
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              color: health.isHealthy
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    health.projectName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Versión ${health.version}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                health.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: health.isHealthy
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildInfoRow('Entorno', health.environment),
                        const SizedBox(height: 8),
                        _buildInfoRow('Estado del Servicio', health.status),
                        const SizedBox(height: 8),
                        _buildInfoRow('Arquitectura', 'Clean Architecture (Dart/Flutter)'),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadHealth,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar Estado'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
