import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/form_definition.dart';
import '../../shared/widgets/dynamic_form/dynamic_form_renderer.dart';
import '../../../core/widgets/haccp_top_bar.dart';
import '../../../core/constants/design_tokens.dart';
import '../../shared/providers/dynamic_form_provider.dart';
import '../providers/gmp_provider.dart';
import '../../../core/widgets/success_overlay.dart';
import '../../../core/widgets/haccp_long_press_button.dart';
import '../../shared/config/form_definitions.dart';

class FoodCoolingFormScreen extends ConsumerWidget {
  const FoodCoolingFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDef = FormDefinitions.coolingFormDef;
    const String formId = 'food_cooling';
    final formState = ref.watch(dynamicFormProvider(formId, formDef));
    final submissionState = ref.watch(gmpFormSubmissionProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Chłodzenie Żywności'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DynamicFormRenderer(
                formId: formId,
                definition: formDef,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(HaccpDesignTokens.standardPadding),
            child: submissionState.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              orElse: () => HaccpLongPressButton(
                label: formState.isValid ? 'ZAPISZ RAPORT' : 'UZUPEŁNIJ DANE',
                color: formState.isValid ? HaccpDesignTokens.success : Colors.grey,
                onCompleted: formState.isValid ? () {
                  _handleSubmit(context, ref, formState, formId);
                } : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proszę uzupełnić wszystkie wymagane pola')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, WidgetRef ref, DynamicFormState state, String formId) async {
    final success = await ref.read(gmpFormSubmissionProvider.notifier).submitLog(
      formId: formId,
      data: state.values,
    );

    if (success && context.mounted) {
      // 1. Show Success Overlay
      await HaccpSuccessOverlay.show(context);
      
      if (!context.mounted) return;

      // 2. Navigate to CCP-3 Report Preview
      final dateStr = state.values['prep_date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0];

      try {
        context.push('/reports/preview/ccp3?date=$dateStr');
      } catch (e) {
        debugPrint('Report navigation failed: $e');
        if (context.mounted) context.pop();
      }

    } else if (!success && context.mounted) {
      final error = ref.read(gmpFormSubmissionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisu: $error'),
          backgroundColor: HaccpDesignTokens.error,
        ),
      );
    }
  }
}
