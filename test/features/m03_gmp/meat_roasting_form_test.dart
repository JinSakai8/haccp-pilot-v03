import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/shared/config/form_definitions.dart';
import 'package:haccp_pilot/features/shared/providers/dynamic_form_provider.dart';

void main() {
  const formId = 'meat_roasting';
  final definition = FormDefinitions.roastingFormDef;

  ProviderContainer buildContainer() => ProviderContainer();

  void fillBaseRequiredFields(DynamicFormNotifier notifier) {
    notifier.updateField('product_name', 'Kurczak');
    notifier.updateField('batch_number', 'B123');
    notifier.updateField('start_time', const TimeOfDay(hour: 8, minute: 0));
    notifier.updateField('internal_temp', 95.0);
  }

  test('CCP2 requires corrective actions when non-compliant', () {
    final container = buildContainer();
    addTearDown(container.dispose);

    final notifier = container.read(
      dynamicFormProvider(formId, definition).notifier,
    );

    fillBaseRequiredFields(notifier);
    notifier.updateField('is_compliant', false);

    final state = container.read(dynamicFormProvider(formId, definition));
    expect(state.fields['corrective_actions']!.isVisible, isTrue);
    expect(state.fields['corrective_actions']!.error, equals('Pole wymagane'));
    expect(state.isValid, isFalse);

    notifier.updateField('corrective_actions', 'Dopieczenie');
    final fixed = container.read(dynamicFormProvider(formId, definition));
    expect(fixed.fields['corrective_actions']!.error, isNull);
  });

  test('CCP2 does not require corrective actions when compliant', () {
    final container = buildContainer();
    addTearDown(container.dispose);

    final notifier = container.read(
      dynamicFormProvider(formId, definition).notifier,
    );

    fillBaseRequiredFields(notifier);
    notifier.updateField('is_compliant', true);

    final state = container.read(dynamicFormProvider(formId, definition));
    expect(state.fields['corrective_actions']!.isVisible, isFalse);
    expect(state.fields['corrective_actions']!.error, isNull);
    expect(state.isValid, isTrue);
  });
}
