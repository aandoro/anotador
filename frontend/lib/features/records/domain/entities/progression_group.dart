import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/utils/measurement_format_utils.dart';

class ProgressionPoint {
  final DateTime date;
  final double weightKg;

  const ProgressionPoint({
    required this.date,
    required this.weightKg,
  });

  String get weightDisplay => MeasurementFormatUtils.formatWeight(weightKg);
  String get formattedDate => DateFormatUtils.formatShortDate(date);
}

class ProgressionGroup {
  final String exerciseName;
  final String? exerciseId;
  final int reps;
  final double currentPrWeight;
  final double? previousWeight;
  final double? deltaKg;
  final List<ProgressionPoint> history;

  const ProgressionGroup({
    required this.exerciseName,
    this.exerciseId,
    required this.reps,
    required this.currentPrWeight,
    this.previousWeight,
    this.deltaKg,
    required this.history,
  });

  String get weightDisplay => MeasurementFormatUtils.formatWeight(currentPrWeight);
  String get repsDisplay => MeasurementFormatUtils.formatReps(reps);
  String? get deltaDisplay => MeasurementFormatUtils.formatDelta(deltaKg);
}
