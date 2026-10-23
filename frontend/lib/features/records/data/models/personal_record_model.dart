import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/personal_record.dart';

class PersonalRecordModel extends PersonalRecord {
  const PersonalRecordModel({
    required super.id,
    required super.exerciseName,
    super.exerciseId,
    required super.weightKg,
    required super.reps,
    required super.date,
    super.notes,
  });

  factory PersonalRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['record_date'] != null) {
      parsedDate = DateTime.tryParse(json['record_date'].toString()) ?? DateTime.now();
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final exName = json['exercise_name'] as String? ?? json['exerciseName'] as String? ?? 'Ejercicio';
    final weight = (json['weight_kg'] as num?)?.toDouble() ?? (json['weightKg'] as num?)?.toDouble() ?? 0.0;
    final reps = (json['reps'] as num?)?.toInt() ?? 1;

    return PersonalRecordModel(
      id: json['id'] as String? ?? '',
      exerciseName: exName,
      exerciseId: json['exercise_id'] as String? ?? json['exerciseId'] as String?,
      weightKg: weight,
      reps: reps,
      date: parsedDate,
      notes: json['notes'] as String?,
    );
  }

  factory PersonalRecordModel.fromEntity(PersonalRecord entity) {
    return PersonalRecordModel(
      id: entity.id,
      exerciseName: entity.exerciseName,
      exerciseId: entity.exerciseId,
      weightKg: entity.weightKg,
      reps: entity.reps,
      date: entity.date,
      notes: entity.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      if (exerciseId != null) 'exercise_id': exerciseId,
      'weight_kg': weightKg,
      'reps': reps,
      'record_date': DateFormatUtils.formatIsoDate(date),
      'notes': (notes != null && notes!.isNotEmpty) ? notes : null,
    };
  }
}
