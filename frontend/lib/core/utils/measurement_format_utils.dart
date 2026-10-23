class MeasurementFormatUtils {
  MeasurementFormatUtils._();

  /// Formatea el peso en kilogramos eliminando decimales redundantes: ej. "80 kg", "82.5 kg"
  static String formatWeight(double weightKg) {
    final isInt = weightKg.truncateToDouble() == weightKg;
    final formatted = isInt ? weightKg.toInt().toString() : weightKg.toString();
    return '$formatted kg';
  }

  /// Formatea la cantidad de repeticiones en singular/plural: ej. "1 rep", "5 reps"
  static String formatReps(int reps) {
    return '$reps ${reps == 1 ? 'rep' : 'reps'}';
  }

  /// Formatea la diferencia de peso (delta): ej. "+5 kg", "-2.5 kg", "= Mismo peso", o null si no aplica
  static String? formatDelta(double? deltaKg) {
    if (deltaKg == null) return null;
    final isInt = deltaKg.truncateToDouble() == deltaKg;
    final formatted = isInt ? deltaKg.abs().toInt().toString() : deltaKg.abs().toString();
    if (deltaKg > 0) {
      return '+$formatted kg';
    } else if (deltaKg < 0) {
      return '-$formatted kg';
    }
    return '= Mismo peso';
  }
}
