import 'package:flutter/material.dart';

class ExerciseUiHelper {
  ExerciseUiHelper._();

  /// Infiere un icono representativo en base al tipo de movimiento o nombre del ejercicio
  static IconData getIconForExercise(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    if (lowerName.contains('militar') ||
        lowerName.contains('hombro') ||
        lowerName.contains('banca')) {
      return Icons.sports_gymnastics;
    } else if (lowerName.contains('dominada') || lowerName.contains('fondo')) {
      return Icons.accessibility_new;
    }
    return Icons.fitness_center;
  }
}
