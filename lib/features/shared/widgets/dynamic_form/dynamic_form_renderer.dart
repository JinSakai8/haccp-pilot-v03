import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../models/form_definition.dart';
import '../../providers/dynamic_form_provider.dart';
import 'haccp_stepper.dart';
import 'haccp_toggle.dart';
import 'haccp_numpad_input.dart';
import 'haccp_dropdown.dart';
import 'haccp_date_picker.dart';
import 'haccp_time_picker.dart';

class DynamicFormRenderer extends ConsumerWidget {
  final String formId;
  final FormDefinition definition;

  const DynamicFormRenderer({
    super.key,
    required this.formId,
    required this.definition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: build_runner needs to be run to generate dynamicFormNotifierProvider
    final state = ref.watch(dynamicFormProvider(formId, definition));
    final notifier = ref.read(dynamicFormProvider(formId, definition).notifier);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(HaccpDesignTokens.standardPadding),
      itemCount: definition.fields.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final config = definition.fields[index];
        final fieldState = state.fields[config.id]!;

        if (!fieldState.isVisible) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildField(config, fieldState, notifier),
            if (fieldState.warning != null) ...[
              const SizedBox(height: 8),
              _buildWarningSection(config, fieldState, notifier),
            ],
            if (fieldState.error != null) ...[
              const SizedBox(height: 4),
              Text(
                fieldState.error!,
                style: const TextStyle(color: HaccpDesignTokens.error, fontSize: 14),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildField(FormFieldConfig config, DynamicFieldState state, DynamicFormNotifier notifier) {
    switch (config.type) {
      case HaccpFieldType.dropdown:
        return HaccpDropdown(
          value: state.value as String?,
          onChanged: (val) => notifier.updateField(config.id, val),
          staticOptions: (config.config['options'] as List<dynamic>?)?.cast<String>(),
          source: config.config['source'] as String?,
          sourceType: config.config['type'] as String?,
        );
      case HaccpFieldType.date:
        return HaccpDatePicker(
          value: state.value is String ? DateTime.tryParse(state.value) : (state.value as DateTime?),
          onChanged: (val) => notifier.updateField(config.id, val),
        );
      case HaccpFieldType.time:
        return HaccpTimePicker(
          value: state.value is String 
             ? TimeOfDay(
                 hour: int.parse((state.value as String).split(':')[0]), 
                 minute: int.parse((state.value as String).split(':')[1])
               ) 
             : (state.value as TimeOfDay?),
          // If the value is stored as "HH:mm" string
          onChanged: (val) => notifier.updateField(config.id, val),
        );
      case HaccpFieldType.stepper:
        return HaccpStepper(
          value: (state.value as num?)?.toDouble() ?? 0.0,
          min: config.config['min']?.toDouble() ?? 0.0,
          max: config.config['max']?.toDouble() ?? 300.0,
          step: config.config['step']?.toDouble() ?? 1.0,
          unit: config.config['unit'] ?? '',
          onChanged: (val) => notifier.updateField(config.id, val),
        );
      case HaccpFieldType.toggle:
        return HaccpToggle(
          value: state.value as bool?,
          onChanged: (val) => notifier.updateField(config.id, val),
        );
      case HaccpFieldType.numpad:
        return HaccpNumPadInput(
           value: (state.value as num?)?.toDouble(),
           onChanged: (val) => notifier.updateField(config.id, val),
           label: config.label,
           maxLength: config.config['maxLength'] ?? 6,
        );
      default:
        // Other types like photo would be implemented here
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text("Widget dla ${config.type.name} wkrótce"),
        );
    }
  }

  Widget _buildWarningSection(FormFieldConfig config, DynamicFieldState state, DynamicFormNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HaccpDesignTokens.warning.withValues(alpha: 0.1),
        border: Border.all(color: HaccpDesignTokens.warning),
        borderRadius: BorderRadius.circular(HaccpDesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: HaccpDesignTokens.warning, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.warning!,
                  style: const TextStyle(
                    color: HaccpDesignTokens.warning, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Wymagany komentarz (wybierz przyczynę):", 
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          _QuickCommentPicker(
            options: const ["Wróciło do pieca", "Odrzucone", "Pieczenie dalej", "Korekta temp.", "Inne"],
            selected: state.comment,
            onSelected: (comment) => notifier.updateComment(config.id, comment),
          ),
        ],
      ),
    );
  }
}

class _QuickCommentPicker extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _QuickCommentPicker({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? HaccpDesignTokens.primary : HaccpDesignTokens.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? HaccpDesignTokens.primary : Colors.white38,
                width: 1.5,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
