import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/exercise_ui_helper.dart';
import '../../domain/entities/progression_group.dart';
import 'one_rep_max_modal.dart';
import 'progression_chart.dart';

class ProgressionCard extends StatefulWidget {
  final String exerciseName;
  final List<ProgressionGroup> groupsForExercise;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const ProgressionCard({
    super.key,
    required this.exerciseName,
    required this.groupsForExercise,
    this.isExpanded = false,
    required this.onToggleExpand,
  });

  @override
  State<ProgressionCard> createState() => _ProgressionCardState();
}

class _ProgressionCardState extends State<ProgressionCard> {
  late int _selectedRepsIndex;

  @override
  void initState() {
    super.initState();
    _selectedRepsIndex = 0;
  }

  @override
  void didUpdateWidget(covariant ProgressionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedRepsIndex >= widget.groupsForExercise.length) {
      _selectedRepsIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupsForExercise.isEmpty) return const SizedBox.shrink();

    final selectedGroup = widget.groupsForExercise[_selectedRepsIndex];
    final bool isOneRepMax = selectedGroup.reps == 1;
    final icon = ExerciseUiHelper.getIconForExercise(widget.exerciseName);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera clickeable: Icono, Nombre del Ejercicio y Chevron de acordeón
            InkWell(
              onTap: widget.onToggleExpand,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(icon, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exerciseName,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.groupsForExercise.length} rango(s) de repeticiones',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      widget.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Cuerpo visible únicamente si isExpanded == true
            if (widget.isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 12),

              // Selector de repeticiones (Chips)
              if (widget.groupsForExercise.length > 1) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: List.generate(widget.groupsForExercise.length, (index) {
                    final grp = widget.groupsForExercise[index];
                    final isSelected = index == _selectedRepsIndex;
                    return ChoiceChip(
                      label: Text(grp.repsDisplay),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRepsIndex = index;
                          });
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.5,
                      ),
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],

              // Panel de Marca Actual y Progreso (Delta)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Récord a ${selectedGroup.repsDisplay}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedGroup.weightDisplay,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Indicador de Delta / Superación de Marca
                    if (selectedGroup.deltaKg != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedGroup.deltaKg! > 0
                              ? AppColors.success.withValues(alpha: 0.12)
                              : (selectedGroup.deltaKg! < 0
                                  ? AppColors.error.withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selectedGroup.deltaKg! > 0
                                  ? Icons.trending_up
                                  : (selectedGroup.deltaKg! < 0
                                      ? Icons.trending_down
                                      : Icons.trending_flat),
                              size: 18,
                              color: selectedGroup.deltaKg! > 0
                                  ? AppColors.success
                                  : (selectedGroup.deltaKg! < 0
                                      ? AppColors.error
                                      : AppColors.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              selectedGroup.deltaDisplay ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: selectedGroup.deltaKg! > 0
                                    ? AppColors.success
                                    : (selectedGroup.deltaKg! < 0
                                        ? AppColors.error
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_outline, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Primer PR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botón exclusivo de Tabla de Porcentajes 1RM cuando reps == 1
              if (isOneRepMax) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    key: const Key('one_rep_max_button'),
                    onPressed: () {
                      OneRepMaxModal.show(
                        context,
                        exerciseName: widget.exerciseName,
                        oneRepMaxWeight: selectedGroup.currentPrWeight,
                      );
                    },
                    icon: const Icon(Icons.calculate_outlined, size: 20),
                    label: const Text(
                      'Ver Tabla de Porcentajes (1RM)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],

              // Gráfico de evolución en el tiempo
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Curva de Evolución',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${selectedGroup.history.length} sesiones registradas',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProgressionChart(points: selectedGroup.history),
            ],
          ],
        ),
      ),
    );
  }
}
