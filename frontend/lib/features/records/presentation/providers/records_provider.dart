import 'package:flutter/material.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/progression_group.dart';
import '../../data/datasources/exercise_remote_datasource.dart';
import '../../data/datasources/personal_record_remote_datasource.dart';

class RecordsProvider extends ChangeNotifier {
  final ExerciseRemoteDataSource exerciseDataSource;
  final PersonalRecordRemoteDataSource? recordDataSource;

  List<PersonalRecord> _records = [];
  List<ProgressionGroup> _progressionGroups = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isSearchingExercises = false;
  String? _errorMessage;

  RecordsProvider({
    required this.exerciseDataSource,
    this.recordDataSource,
    List<PersonalRecord>? initialRecords,
    List<ProgressionGroup>? initialProgressionGroups,
  }) {
    if (initialRecords != null) {
      _records = List.from(initialRecords);
    }
    if (initialProgressionGroups != null) {
      _progressionGroups = List.from(initialProgressionGroups);
    } else if (initialRecords != null && initialRecords.isNotEmpty) {
      _recalculateLocalProgression();
    }
  }

  List<PersonalRecord> get records => List.unmodifiable(_records);
  List<ProgressionGroup> get progressionGroups => List.unmodifiable(_progressionGroups);
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isSearchingExercises => _isSearchingExercises;
  String? get errorMessage => _errorMessage;

  /// Carga los récords personales y el resumen de progresión desde el backend
  Future<void> loadRecords() async {
    if (recordDataSource == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        recordDataSource!.fetchUserRecords(),
        recordDataSource!.fetchProgressionSummary(),
      ]);
      _records = results[0] as List<PersonalRecord>;
      _progressionGroups = results[1] as List<ProgressionGroup>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga explícita del resumen de progresión
  Future<void> loadProgression() async {
    if (recordDataSource == null) return;

    try {
      _progressionGroups = await recordDataSource!.fetchProgressionSummary();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Guarda un nuevo récord personal en el backend y refresca las progresiones
  Future<bool> addRecord(PersonalRecord record) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (recordDataSource == null) {
      _records.insert(0, record);
      _recalculateLocalProgression();
      _isActionLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final savedRecord = await recordDataSource!.createRecord(record);
      _records.insert(0, savedRecord);

      try {
        _progressionGroups = await recordDataSource!.fetchProgressionSummary();
      } catch (_) {
        _recalculateLocalProgression();
      }

      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un récord personal existente y sincroniza las progresiones
  Future<bool> updateRecord(PersonalRecord record) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (recordDataSource == null) {
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
        _recalculateLocalProgression();
        _isActionLoading = false;
        notifyListeners();
        return true;
      }
      _isActionLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final updated = await recordDataSource!.updateRecord(record);
      final index = _records.indexWhere((r) => r.id == updated.id);
      if (index != -1) {
        _records[index] = updated;
      } else {
        _records.insert(0, updated);
      }

      try {
        _progressionGroups = await recordDataSource!.fetchProgressionSummary();
      } catch (_) {
        _recalculateLocalProgression();
      }

      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Elimina un récord personal por su ID y recalcula las progresiones
  Future<bool> deleteRecord(String recordId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (recordDataSource == null) {
      _records.removeWhere((r) => r.id == recordId);
      _recalculateLocalProgression();
      _isActionLoading = false;
      notifyListeners();
      return true;
    }

    try {
      await recordDataSource!.deleteRecord(recordId);
      _records.removeWhere((r) => r.id == recordId);

      try {
        _progressionGroups = await recordDataSource!.fetchProgressionSummary();
      } catch (_) {
        _recalculateLocalProgression();
      }

      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Recálculo local defensivo de progresiones cuando no hay backend o falla la consulta
  void _recalculateLocalProgression() {
    final Map<String, List<PersonalRecord>> grouped = {};
    for (final r in _records) {
      final key = '${r.exerciseName.trim().toLowerCase()}_${r.reps}';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final List<ProgressionGroup> result = [];
    grouped.forEach((_, items) {
      items.sort((a, b) => a.date.compareTo(b.date));
      final first = items.first;
      final history = items
          .map((item) => ProgressionPoint(date: item.date, weightKg: item.weightKg))
          .toList();
      final maxWeight = items.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);

      double? previousWeight;
      double? delta;
      if (items.length >= 2) {
        previousWeight = items[items.length - 2].weightKg;
        delta = double.parse((items.last.weightKg - previousWeight).toStringAsFixed(2));
      }

      result.add(ProgressionGroup(
        exerciseName: first.exerciseName,
        exerciseId: first.exerciseId,
        reps: first.reps,
        currentPrWeight: maxWeight,
        previousWeight: previousWeight,
        deltaKg: delta,
        history: history,
      ));
    });

    result.sort((a, b) {
      final comp = a.exerciseName.toLowerCase().compareTo(b.exerciseName.toLowerCase());
      if (comp != 0) return comp;
      return a.reps.compareTo(b.reps);
    });

    _progressionGroups = result;
  }

  /// Búsqueda dinámica de ejercicios con autocompletado
  Future<List<Exercise>> searchExercises(String query) async {
    final clean = query.trim();
    if (clean.length < 3) return [];

    _isSearchingExercises = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await exerciseDataSource.searchExercises(clean);
      _isSearchingExercises = false;
      notifyListeners();
      return results;
    } catch (e) {
      _errorMessage = e.toString();
      _isSearchingExercises = false;
      notifyListeners();
      return [];
    }
  }
}
