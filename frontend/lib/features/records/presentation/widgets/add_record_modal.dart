import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/personal_record.dart';
import '../providers/records_provider.dart';

class AddRecordModal extends StatefulWidget {
  final PersonalRecord? recordToEdit;

  const AddRecordModal({super.key, this.recordToEdit});

  @override
  State<AddRecordModal> createState() => _AddRecordModalState();
}

class _AddRecordModalState extends State<AddRecordModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _exerciseController;
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _notesController;

  Exercise? _selectedExercise;
  DateTime _selectedDate = DateTime.now();

  Timer? _debounceTimer;
  List<Exercise> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isSubmitting = false;
  String? _exerciseValidationError;

  bool get isEditing => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    final pr = widget.recordToEdit;
    if (pr != null) {
      _exerciseController = TextEditingController(text: pr.exerciseName);
      final isInt = pr.weightKg.truncateToDouble() == pr.weightKg;
      _weightController = TextEditingController(
        text: isInt ? pr.weightKg.toInt().toString() : pr.weightKg.toString(),
      );
      _repsController = TextEditingController(text: pr.reps.toString());
      _notesController = TextEditingController(text: pr.notes ?? '');
      _selectedDate = pr.date;
      _selectedExercise = Exercise(
        id: pr.exerciseId ?? '',
        name: pr.exerciseName,
      );
    } else {
      _exerciseController = TextEditingController();
      _weightController = TextEditingController();
      _repsController = TextEditingController(text: '1');
      _notesController = TextEditingController();
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _exerciseController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onExerciseInputChanged(String query) {
    _debounceTimer?.cancel();

    // Si el usuario modifica el texto tras seleccionar, desvinculamos la selección
    if (_selectedExercise != null && _selectedExercise!.name != query) {
      setState(() {
        _selectedExercise = null;
      });
    }

    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
        _exerciseValidationError = null;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _exerciseValidationError = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final recordsProvider = context.read<RecordsProvider>();
      final results = await recordsProvider.searchExercises(query);

      if (!mounted) return;

      setState(() {
        _suggestions = results;
        _isLoadingSuggestions = false;
      });
    });
  }

  void _selectExercise(Exercise exercise) {
    setState(() {
      _selectedExercise = exercise;
      _exerciseController.text = exercise.name;
      _suggestions = [];
      _exerciseValidationError = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      if (_selectedExercise == null ||
          _exerciseController.text.trim() != _selectedExercise!.name) {
        _exerciseValidationError =
            'Debes buscar (mín. 3 letras) y seleccionar un ejercicio de la lista.';
      } else {
        _exerciseValidationError = null;
      }
    });

    if (!_formKey.currentState!.validate() || _exerciseValidationError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final weight = double.parse(_weightController.text.replaceAll(',', '.'));
    final reps = int.parse(_repsController.text);

    final rawNotes = _notesController.text.trim();
    final notes = rawNotes.isNotEmpty ? rawNotes : null;

    final record = PersonalRecord(
      id: isEditing ? widget.recordToEdit!.id : '',
      exerciseName: _selectedExercise!.name,
      exerciseId: _selectedExercise!.id.isNotEmpty ? _selectedExercise!.id : null,
      weightKg: weight,
      reps: reps,
      date: _selectedDate,
      notes: notes,
    );

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final provider = context.read<RecordsProvider>();

    final success = isEditing
        ? await provider.updateRecord(record)
        : await provider.addRecord(record);

    if (!mounted) return;

    if (success) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? '¡PR de ${record.exerciseName} actualizado con éxito!'
                : '¡PR de ${record.exerciseName} (${record.weightDisplay}) registrado con éxito!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
      });
      final err = provider.errorMessage;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            err ?? (isEditing ? 'Error al actualizar el PR' : 'Error al guardar el PR'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_isSubmitting,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomInset + 20,
            ),
            child: Material(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              elevation: 8,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AbsorbPointer(
                  absorbing: _isSubmitting,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEditing ? Icons.edit_note : Icons.add_chart_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEditing ? 'Editar Récord Personal' : 'Cargar Nuevo PR',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            ),
                          ],
                        ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing
                          ? 'Modifica los valores de peso, repeticiones o fecha de tu marca.'
                          : 'Busca el ejercicio en la base de datos y define tu nueva marca.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo de búsqueda de ejercicio con debounce
                    TextFormField(
                      controller: _exerciseController,
                      decoration: InputDecoration(
                        labelText: 'Ejercicio (escribe 3+ letras para buscar)',
                        prefixIcon: const Icon(Icons.fitness_center),
                        suffixIcon: _isLoadingSuggestions
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_selectedExercise != null
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                  )
                                : null),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        errorText: _exerciseValidationError,
                      ),
                      onChanged: _onExerciseInputChanged,
                    ),

                    // Lista desplegable de sugerencias de ejercicios
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final exercise = _suggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                exercise.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              onTap: () => _selectExercise(exercise),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Fila con Peso y Repeticiones
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Peso',
                              suffixText: 'kg',
                              prefixIcon: Icon(Icons.scale_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Ingresa el peso';
                              }
                              final numVal = double.tryParse(val.replaceAll(',', '.'));
                              if (numVal == null || numVal <= 0) {
                                return 'Peso mayor a 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _repsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Reps',
                              prefixIcon: Icon(Icons.repeat),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Mín. 1';
                              }
                              final intVal = int.tryParse(val);
                              if (intVal == null || intVal < 1) {
                                return '>= 1';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Selector de Fecha
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha de la marca',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  DateFormatUtils.formatFullDate(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo opcional de Notas u Observaciones
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Notas u observaciones (opcional)',
                        hintText: 'Ej. RPE 9, cinturón usado, buena técnica...',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón Guardar / Actualizar
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Guardar Cambios' : 'Guardar PR',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
