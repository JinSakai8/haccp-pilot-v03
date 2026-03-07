import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/form_definition.dart';

part 'dynamic_form_provider.g.dart';

class DynamicFormState {
  final Map<String, DynamicFieldState> fields;
  final bool isSubmitting;

  DynamicFormState({required this.fields, this.isSubmitting = false});

  bool get isValid {
    return fields.values.every((f) {
      if (!f.isVisible) return true;
      if (f.error != null) return false;
      // If there's a warning, a comment is mandatory
      if (f.warning != null && (f.comment == null || f.comment!.isEmpty))
        return false;
      return true;
    });
  }

  /// Helper to get simple Map<id, value>
  Map<String, dynamic> get values =>
      fields.map((key, state) => MapEntry(key, state.value));

  DynamicFormState copyWith({
    Map<String, DynamicFieldState>? fields,
    bool? isSubmitting,
  }) {
    return DynamicFormState(
      fields: fields ?? this.fields,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

@riverpod
class DynamicFormNotifier extends _$DynamicFormNotifier {
  @override
  DynamicFormState build(String formId, FormDefinition definition) {
    final initialFields = <String, DynamicFieldState>{};

    for (final config in definition.fields) {
      initialFields[config.id] = DynamicFieldState(
        value: _getInitialValue(config),
      );
    }

    // Update initial visibility
    for (final config in definition.fields) {
      initialFields[config.id] = initialFields[config.id]!.copyWith(
        isVisible: _calculateVisibility(config, initialFields),
      );
    }

    return DynamicFormState(fields: initialFields);
  }

  dynamic _getInitialValue(FormFieldConfig config) {
    switch (config.type) {
      case HaccpFieldType.stepper:
        return config.config['default']?.toDouble() ?? 0.0;
      case HaccpFieldType.toggle:
        return null;
      case HaccpFieldType.dropdown:
        return null;
      case HaccpFieldType.photo:
        return [];
      case HaccpFieldType.numpad:
        return null;
      default:
        return null;
    }
  }

  bool _calculateVisibility(
    FormFieldConfig config,
    Map<String, DynamicFieldState> currentFields,
  ) {
    if (config.visibleIf == null) return true;
    return _matchesCondition(config.visibleIf!, currentFields);
  }

  bool _matchesCondition(
    Map<String, dynamic> condition,
    Map<String, DynamicFieldState> currentFields,
  ) {
    final parentId = condition['field']?.toString();
    if (parentId == null || parentId.isEmpty) return false;
    final expectedValue = condition['value'];
    final parentState = currentFields[parentId];
    return parentState?.value == expectedValue;
  }

  bool _isMissingValue(dynamic value) {
    return value == null ||
        (value is String && value.trim().isEmpty) ||
        (value is List && value.isEmpty);
  }

  bool _isConditionallyRequired(
    FormFieldConfig config,
    Map<String, DynamicFieldState> currentFields,
  ) {
    if (config.requiredIf == null) return false;
    return _matchesCondition(config.requiredIf!, currentFields);
  }

  void updateField(String fieldId, dynamic newValue) {
    // Re-read definition to get config (this is safe as it's passed to build)
    final config = definition.fields.firstWhere((f) => f.id == fieldId);

    final updatedFields = Map<String, DynamicFieldState>.from(state.fields);
    final fieldState = updatedFields[fieldId]!;

    // Validation
    String? error;
    if ((config.required || _isConditionallyRequired(config, updatedFields)) &&
        _isMissingValue(newValue)) {
      error = "Pole wymagane";
    }

    String? warning;
    if (newValue is double) {
      if (config.minWarning != null && newValue < config.minWarning!) {
        warning = "Wartość poza normą (min: ${config.minWarning})";
      } else if (config.maxWarning != null && newValue > config.maxWarning!) {
        warning = "Wartość poza normą (max: ${config.maxWarning})";
      }
    }

    updatedFields[fieldId] = fieldState.copyWith(
      value: newValue,
      error: error,
      warning: warning,
      comment: warning == null
          ? null
          : fieldState.comment, // Clear comment if warning resolved
    );

    // Update visibility of dependent fields
    for (final cfg in definition.fields) {
      final isVisible = _calculateVisibility(cfg, updatedFields);
      if (updatedFields[cfg.id]!.isVisible != isVisible) {
        updatedFields[cfg.id] = updatedFields[cfg.id]!.copyWith(
          isVisible: isVisible,
        );
      }

      if (isVisible && _isConditionallyRequired(cfg, updatedFields)) {
        final dependentState = updatedFields[cfg.id]!;
        final needsError = _isMissingValue(dependentState.value);
        if (needsError && dependentState.error == null) {
          updatedFields[cfg.id] = dependentState.copyWith(
            error: "Pole wymagane",
          );
        } else if (!needsError && dependentState.error == "Pole wymagane") {
          updatedFields[cfg.id] = dependentState.copyWith(error: null);
        }
      }
    }

    state = state.copyWith(fields: updatedFields);
  }

  void updateComment(String fieldId, String comment) {
    final updatedFields = Map<String, DynamicFieldState>.from(state.fields);
    updatedFields[fieldId] = updatedFields[fieldId]!.copyWith(comment: comment);
    state = state.copyWith(fields: updatedFields);
  }
}
