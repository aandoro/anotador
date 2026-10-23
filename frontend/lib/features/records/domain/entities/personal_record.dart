import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/utils/measurement_format_utils.dart';

class PersonalRecord {
  final String id;
  final String exerciseName;
  final String? exerciseId;
  final double weightKg;
  final int reps;
  final DateTime date;
  final String? notes;

  const PersonalRecord({
    required this.id,
    required this.exerciseName,
    this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.date,
    this.notes,
  });

  String get weightDisplay => MeasurementFormatUtils.formatWeight(weightKg);
  String get repsDisplay => MeasurementFormatUtils.formatReps(reps);
  String get formattedDate => DateFormatUtils.formatFullDate(date);
}
