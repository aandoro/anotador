import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/measurement_format_utils.dart';

class OneRepMaxModal extends StatefulWidget {
  final String exerciseName;
  final double oneRepMaxWeight;

  const OneRepMaxModal({
    super.key,
    required this.exerciseName,
    required this.oneRepMaxWeight,
  });

  /// Abre el Modal Bottom Sheet con la tabla de porcentajes 1RM
  static Future<void> show(
    BuildContext context, {
    required String exerciseName,
    required double oneRepMaxWeight,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OneRepMaxModal(
        exerciseName: exerciseName,
        oneRepMaxWeight: oneRepMaxWeight,
      ),
    );
  }

  @override
  State<OneRepMaxModal> createState() => _OneRepMaxModalState();
}

class _OneRepMaxModalState extends State<OneRepMaxModal> {
  int _step = 5; // Granularidad por defecto: Cada 5%

  List<int> get _percentages {
    final list = <int>[];
    for (int p = 100; p >= 10; p -= _step) {
      list.add(p);
    }
    return list;
  }

  String _getEstimatedReps(int percentage) {
    if (percentage >= 100) return '1 rep (1RM)';
    if (percentage >= 95) return '~2 reps';
    if (percentage >= 90) return '~3 - 4 reps';
    if (percentage >= 85) return '~5 - 6 reps';
    if (percentage >= 80) return '~7 - 8 reps';
    if (percentage >= 75) return '~9 - 10 reps';
    if (percentage >= 70) return '~11 - 12 reps';
    if (percentage >= 65) return '~13 - 15 reps';
    if (percentage >= 60) return '~16 - 20 reps';
    if (percentage >= 50) return 'Calentamiento / Técnica';
    return 'Calentamiento';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.82;
    final percentages = _percentages;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de arrastre (drag handle)
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Cabecera con título, subtítulo formateado y botón de cierre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tabla de Porcentajes (1RM)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.exerciseName} • 100% = ${MeasurementFormatUtils.formatWeight(widget.oneRepMaxWeight)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Selector de granularidad (Cada 5% o Cada 10%)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  const Text(
                    'Granularidad:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    key: const Key('granularity_step_5'),
                    label: const Text('Cada 5%'),
                    selected: _step == 5,
                    onSelected: (selected) {
                      if (selected && _step != 5) {
                        setState(() => _step = 5);
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _step == 5 ? Colors.white : AppColors.textPrimary,
                      fontWeight: _step == 5 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('granularity_step_10'),
                    label: const Text('Cada 10%'),
                    selected: _step == 10,
                    onSelected: (selected) {
                      if (selected && _step != 10) {
                        setState(() => _step = 10);
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _step == 10 ? Colors.white : AppColors.textPrimary,
                      fontWeight: _step == 10 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ],
              ),
            ),

            // Encabezados de columnas de la tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              color: AppColors.background,
              child: const Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      '% 1RM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Peso Calculado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Reps Estimadas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Lista scrollable de porcentajes
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                itemCount: percentages.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: AppColors.cardBorder,
                ),
                itemBuilder: (context, index) {
                  final pct = percentages[index];
                  final calculatedWeight =
                      (widget.oneRepMaxWeight * pct / 100 * 10).round() / 10;
                  final formattedWeight =
                      MeasurementFormatUtils.formatWeight(calculatedWeight);
                  final repsGuide = _getEstimatedReps(pct);
                  final is100 = pct == 100;

                  Color badgeBg;
                  Color badgeText;
                  if (is100) {
                    badgeBg = AppColors.primary;
                    badgeText = Colors.white;
                  } else if (pct >= 85) {
                    badgeBg = AppColors.primary.withValues(alpha: 0.15);
                    badgeText = AppColors.primaryDark;
                  } else if (pct >= 70) {
                    badgeBg = AppColors.secondary.withValues(alpha: 0.15);
                    badgeText = AppColors.secondary;
                  } else {
                    badgeBg = Colors.grey.withValues(alpha: 0.12);
                    badgeText = AppColors.textSecondary;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        // Badge de Porcentaje
                        Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: badgeText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Peso Calculado
                        Expanded(
                          child: Text(
                            formattedWeight,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: is100 ? FontWeight.w800 : FontWeight.bold,
                              color: is100
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // Guía Orientativa de Repeticiones Estimadas
                        Text(
                          repsGuide,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: is100 ? FontWeight.bold : FontWeight.w500,
                            color: is100
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
