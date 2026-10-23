class DateFormatUtils {
  DateFormatUtils._();

  static const List<String> shortMonths = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  /// Formatea la fecha en formato largo: "09 Oct 2026"
  static String formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = shortMonths[date.month - 1];
    final year = date.year.toString();
    return '$day $month $year';
  }

  /// Formatea la fecha en formato corto: "09 Oct"
  static String formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = shortMonths[date.month - 1];
    return '$day $month';
  }

  /// Formatea la fecha en formato ISO estándar: "2026-10-09"
  static String formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
