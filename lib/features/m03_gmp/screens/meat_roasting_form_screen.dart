import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/form_definition.dart';
import '../../shared/widgets/dynamic_form/dynamic_form_renderer.dart';
import '../../../core/widgets/haccp_top_bar.dart';
import '../../../core/constants/design_tokens.dart';
import '../../shared/providers/dynamic_form_provider.dart';

class MeatRoastingFormScreen extends ConsumerWidget {
  const MeatRoastingFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This definition would normally come from a repository/DB
    final roastingFormDef = FormDefinition(
      fields: [
        FormFieldConfig(
          id: 'product_name',
          type: HaccpFieldType.dropdown,
          label: 'Produkt',
          config: {'options': ['Kurczak Pieczony', 'Uda z Kurczaka', 'Skrzydełka']},
          required: true,
        ),
        FormFieldConfig(
          id: 'internal_temp',
          type: HaccpFieldType.stepper,
          label: 'Temp. Wewnętrzna [°C]',
          config: {
            'min': 0, 
            'max': 120, 
            'step': 1, 
            'unit': '°C',
            'default': 75.0,
            'warningRange': {'min': 75.0} // Warning if < 75
          },
          required: true,
        ),
      ],
    );

    const String formId = 'meat_roasting_daily';
    // Manual submit logic would go here, reading the provider
    // final notifier = ref.read(dynamicFormProvider('roasting_form', roastingFormDef).notifier);
    
    // DynamicFormNotifier is parameter-dependent
    final formState = ref.watch(dynamicFormProvider(formId, roastingFormDef));

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Pieczenie Mięs'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DynamicFormRenderer(
                formId: formId,
                definition: roastingFormDef,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(HaccpDesignTokens.standardPadding),
            child: SizedBox(
              width: double.infinity,
              height: HaccpDesignTokens.minTouchTarget,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: formState.isValid 
                      ? HaccpDesignTokens.success 
                      : HaccpDesignTokens.surface.withValues(alpha: 0.5),
                  elevation: formState.isValid ? 4 : 0,
                ),
                onPressed: formState.isValid ? () {
                  _handleSubmit(context, ref, formState);
                } : null,
                child: Text(
                  formState.isValid ? 'ZAPISZ RAPORT' : 'UZUPEŁNIJ DANE', 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(BuildContext context, WidgetRef ref, DynamicFormState state) {
    // Implementation of save logic would go to a repository
    // For now: Show feedback and pop
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Raport zapisany pomyślnie!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: HaccpDesignTokens.success,
        duration: Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) context.pop();
    });
  }
}
