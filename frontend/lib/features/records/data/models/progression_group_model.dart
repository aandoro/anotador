import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/progression_group.dart';

class ProgressionPointModel extends ProgressionPoint {
  const ProgressionPointModel({
    required super.date,
    required super.weightKg,
  });

  factory ProgressionPointModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['record_date'] != null) {
      parsedDate = DateTime.tryParse(json['record_date'].toString()) ?? DateTime.now();
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final weight = (json['weight_kg'] as num?)?.toDouble() ?? 0.0;

    return ProgressionPointModel(
      date: parsedDate,
      weightKg: weight,
    );
  }

  factory ProgressionPointModel.fromEntity(ProgressionPoint entity) {
    return ProgressionPointModel(
      date: entity.date,
      weightKg: entity.weightKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record_date': DateFormatUtils.formatIsoDate(date),
      'weight_kg': weightKg,
    };
  }
}

class ProgressionGroupModel extends ProgressionGroup {
  const ProgressionGroupModel({
    required super.exerciseName,
    super.exerciseId,
    required super.reps,
    required super.currentPrWeight,
    super.previousWeight,
    super.deltaKg,
    required super.history,
  });

  factory ProgressionGroupModel.fromJson(Map<String, dynamic> json) {
    final exName = json['exercise_name'] as String? ?? 'Ejercicio';
    final reps = (json['reps'] as num?)?.toInt() ?? 1;
    final currentPr = (json['current_pr_weight'] as num?)?.toDouble() ?? 0.0;
    final prevWeight = (json['previous_weight'] as num?)?.toDouble();
    final delta = (json['delta_kg'] as num?)?.toDouble();

    final historyRaw = json['history'] as List<dynamic>? ?? [];
    final historyList = historyRaw
        .map((item) => ProgressionPointModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return ProgressionGroupModel(
      exerciseName: exName,
      exerciseId: json['exercise_id'] as String?,
      reps: reps,
      currentPrWeight: currentPr,
      previousWeight: prevWeight,
      deltaKg: delta,
      history: historyList,
    );
  }

  factory ProgressionGroupModel.fromEntity(ProgressionGroup entity) {
    return ProgressionGroupModel(
      exerciseName: entity.exerciseName,
      exerciseId: entity.exerciseId,
      reps: entity.reps,
      currentPrWeight: entity.currentPrWeight,
      previousWeight: entity.previousWeight,
      deltaKg: entity.deltaKg,
      history: entity.history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      if (exerciseId != null) 'exercise_id': exerciseId,
      'reps': reps,
      'current_pr_weight': currentPrWeight,
      if (previousWeight != null) 'previous_weight': previousWeight,
      if (deltaKg != null) 'delta_kg': deltaKg,
      'history': history
          .map((p) => ProgressionPointModel.fromEntity(p).toJson())
          .toList(),
    };
  }
}
