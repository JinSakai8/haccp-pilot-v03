enum HaccpFieldType {
  stepper,
  toggle,
  time,
  date,
  dropdown,
  numpad,
  photo,
  text,
}

class FormFieldConfig {
  final String id;
  final HaccpFieldType type;
  final String label;
  final Map<String, dynamic> config;
  final bool required;
  final Map<String, dynamic>? visibleIf; // { "field": "other_id", "value": true }

  FormFieldConfig({
    required this.id,
    required this.type,
    required this.label,
    this.config = const {},
    this.required = false,
    this.visibleIf,
  });

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) {
    return FormFieldConfig(
      id: json['id'] as String,
      type: HaccpFieldType.values.firstWhere((e) => e.name == json['type'], orElse: () => HaccpFieldType.stepper),
      label: json['label'] as String,
      config: json['config'] as Map<String, dynamic>? ?? const {},
      required: json['required'] as bool? ?? false,
      visibleIf: json['visibleIf'] as Map<String, dynamic>?,
    );
  }

  // Warning logic helpers
  double? get minWarning => (config['warningRange'] as Map?)?['min']?.toDouble();
  double? get maxWarning => (config['warningRange'] as Map?)?['max']?.toDouble();
}

class FormDefinition {
  final List<FormFieldConfig> fields;
  final String title;

  FormDefinition({
    required this.fields,
    this.title = 'Raport',
  });

  factory FormDefinition.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as List;
    return FormDefinition(
      fields: fieldsJson.map((f) => FormFieldConfig.fromJson(f as Map<String, dynamic>)).toList(),
      title: json['title'] as String? ?? 'Raport',
    );
  }
}

class DynamicFieldState {
  final dynamic value;
  final String? error;
  final String? warning;
  final String? comment;
  final bool isVisible;

  DynamicFieldState({
    required this.value,
    this.error,
    this.warning,
    this.comment,
    this.isVisible = true,
  });

  DynamicFieldState copyWith({
    dynamic value,
    String? error,
    String? warning,
    String? comment,
    bool? isVisible,
  }) {
    return DynamicFieldState(
      value: value ?? this.value,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      comment: comment ?? this.comment,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
