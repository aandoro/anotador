import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/exercise_ui_helper.dart';
import '../../data/datasources/exercise_remote_datasource.dart';
import '../../data/datasources/personal_record_remote_datasource.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/progression_group.dart';
import '../providers/records_provider.dart';
import '../widgets/add_record_modal.dart';
import '../widgets/progression_card.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Si la app está en sesión activa durante Hot Reload y main() no se ha re-ejecutado,
    // proveemos una instancia fallback para evitar ProviderNotFoundException
    bool hasProvider = false;
    try {
      Provider.of<RecordsProvider>(context, listen: false);
      hasProvider = true;
    } catch (_) {
      hasProvider = false;
    }

    if (!hasProvider) {
      final apiClient = ApiClient();
      return ChangeNotifierProvider(
        create: (_) => RecordsProvider(
          exerciseDataSource: ExerciseRemoteDataSourceImpl(apiClient: apiClient),
          recordDataSource: PersonalRecordRemoteDataSourceImpl(apiClient: apiClient),
        ),
        child: const _RecordsScreenContent(),
      );
    }

    return const _RecordsScreenContent();
  }
}

class _RecordsScreenContent extends StatefulWidget {
  const _RecordsScreenContent();

  @override
  State<_RecordsScreenContent> createState() => _RecordsScreenContentState();
}

class _RecordsScreenContentState extends State<_RecordsScreenContent> {
  String? _expandedExerciseName; // Todas las cards inician colapsadas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RecordsProvider>().loadRecords();
      }
    });
  }

  void _handleToggleCard(String exerciseName) {
    setState(() {
      if (_expandedExerciseName == exerciseName) {
        _expandedExerciseName = null;
      } else {
        _expandedExerciseName = exerciseName;
      }
    });
  }

  void _openAddRecordModal(BuildContext context, [PersonalRecord? recordToEdit]) {
    final recordsProvider = context.read<RecordsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: recordsProvider,
        child: AddRecordModal(recordToEdit: recordToEdit),
      ),
    );
  }

  Future<void> _confirmDeleteRecord(BuildContext context, PersonalRecord pr) async {
    final recordsProvider = context.read<RecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return PopScope(
              canPop: !isDeleting,
              child: AlertDialog(
                title: const Text('Eliminar Récord Personal'),
                content: Text(
                  '¿Estás seguro de que deseas eliminar este PR de ${pr.exerciseName} (${pr.weightDisplay})? Esta acción no se puede deshacer.',
                ),
                actions: [
                  TextButton(
                    onPressed: isDeleting ? null : () => Navigator.pop(dialogContext, null),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setDialogState(() {
                              isDeleting = true;
                            });
                            final result = await recordsProvider.deleteRecord(pr.id);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, result);
                            }
                          },
                    child: isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Eliminar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (success != null && context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Récord personal eliminado correctamente'
                : (recordsProvider.errorMessage ?? 'Error al eliminar el récord personal'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsProvider = context.watch<RecordsProvider>();
    final prs = recordsProvider.records;
    final progressionGroups = recordsProvider.progressionGroups;
    final isLoading = recordsProvider.isLoading;

    // Agrupar progresiones por nombre de ejercicio para consolidar variantes de repeticiones
    final Map<String, List<ProgressionGroup>> exerciseGroups = {};
    for (final group in progressionGroups) {
      exerciseGroups.putIfAbsent(group.exerciseName, () => []).add(group);
    }
    exerciseGroups.forEach((_, list) {
      list.sort((a, b) => a.reps.compareTo(b.reps));
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Records (PRs)'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar récords',
              onPressed: () => recordsProvider.loadRecords(),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.surface,
            indicatorWeight: 3,
            labelColor: AppColors.surface,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelColor: AppColors.background.withValues(alpha: 0.72),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(
                icon: Icon(Icons.show_chart),
                text: 'Progresión',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Historial',
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: isLoading && prs.isEmpty && progressionGroups.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Cargando tus marcas y progresiones...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  children: [
                    // Pestaña 1: Progresión y Evolución Gráfica
                    RefreshIndicator(
                      onRefresh: () => recordsProvider.loadRecords(),
                      child: exerciseGroups.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(20.0),
                              children: [
                                _buildHeaderBanner(
                                  title: 'Evolución de Marcas',
                                  subtitle:
                                      'Analiza el incremento de peso en cada ejercicio y rango de repeticiones.',
                                  icon: Icons.trending_up,
                                ),
                                const SizedBox(height: 48),
                                _buildEmptyState(
                                  title: 'Sin progresiones registradas',
                                  subtitle:
                                      'Registra tus levantamientos para ver cómo sube tu fuerza con gráficos interactivos.',
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.all(20.0),
                              children: [
                                _buildHeaderBanner(
                                  title: 'Evolución de Marcas',
                                  subtitle:
                                      'Tus PRs agrupados por ejercicio. Compara repeticiones y visualiza la curva de carga.',
                                  icon: Icons.trending_up,
                                ),
                                const SizedBox(height: 16),
                                ...exerciseGroups.entries.map(
                                  (entry) => ProgressionCard(
                                    exerciseName: entry.key,
                                    groupsForExercise: entry.value,
                                    isExpanded: _expandedExerciseName == entry.key,
                                    onToggleExpand: () => _handleToggleCard(entry.key),
                                  ),
                                ),
                                const SizedBox(height: 60), // Margen para el FAB
                              ],
                            ),
                    ),

                    // Pestaña 2: Historial Cronológico con edición y eliminación
                    RefreshIndicator(
                      onRefresh: () => recordsProvider.loadRecords(),
                      child: prs.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(20.0),
                              children: [
                                _buildHeaderBanner(
                                  title: 'Historial Completo',
                                  subtitle:
                                      'Lista cronológica de todos los récords personales registrados.',
                                  icon: Icons.emoji_events,
                                ),
                                const SizedBox(height: 48),
                                _buildEmptyState(
                                  title: 'Aún no tienes récords cargados',
                                  subtitle:
                                      'Registra tus levantamientos y marcas máximas pulsando el botón + Nuevo PR.',
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.all(20.0),
                              children: [
                                _buildHeaderBanner(
                                  title: 'Historial Completo',
                                  subtitle:
                                      'Visualiza, edita o elimina los registros cargados ordenados por fecha.',
                                  icon: Icons.emoji_events,
                                ),
                                const SizedBox(height: 16),
                                ...prs.map((pr) => Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: AppColors.cardBorder.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              AppColors.primary.withValues(alpha: 0.12),
                                          child: Icon(
                                            ExerciseUiHelper.getIconForExercise(pr.exerciseName),
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        title: Text(
                                          pr.exerciseName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${pr.repsDisplay} • ${pr.formattedDate}'),
                                            if (pr.notes != null && pr.notes!.trim().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.sticky_note_2_outlined,
                                                    size: 14,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      pr.notes!.trim(),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontStyle: FontStyle.italic,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              pr.weightDisplay,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                            ),
                                            const SizedBox(width: 4),
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: AppColors.textSecondary,
                                              ),
                                              tooltip: 'Opciones',
                                              onSelected: (action) {
                                                if (action == 'edit') {
                                                  _openAddRecordModal(context, pr);
                                                } else if (action == 'delete') {
                                                  _confirmDeleteRecord(context, pr);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 20,
                                                        color: AppColors.primary,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Editar'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        size: 20,
                                                        color: AppColors.error,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Eliminar',
                                                        style: TextStyle(color: AppColors.error),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: 60), // Margen para el FAB
                              ],
                            ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddRecordModal(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo PR'),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
