import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../shared/widgets/dynamic_form/dynamic_form_renderer.dart';
import '../../shared/models/form_definition.dart';
import '../../shared/config/checklist_definitions.dart';
import '../providers/ghp_provider.dart';
import '../../../core/widgets/success_overlay.dart';
import '../../../core/constants/design_tokens.dart';
import '../../shared/providers/dynamic_form_provider.dart';
import '../../../core/widgets/haccp_long_press_button.dart';

class GhpChecklistScreen extends ConsumerWidget {
  final String categoryId;

  const GhpChecklistScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = ChecklistDefinitions.ghpDefinitions[categoryId];
    
    // Fallback if category not found
    if (definition == null) {
      return Scaffold(
        appBar: const HaccpTopBar(title: 'Błąd'),
        body: Center(child: Text('Nieznana kategoria: $categoryId')),
      );
    }

    final formId = 'ghp_$categoryId';
    // Watch form state to enable/disable button
    final formState = ref.watch(dynamicFormProvider(formId, definition));
    final submissionState = ref.watch(ghpFormSubmissionProvider);

    return Scaffold(
      appBar: HaccpTopBar(title: 'Checklista: ${_getCategoryName(categoryId)}'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DynamicFormRenderer(
                formId: formId,
                definition: definition,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(HaccpDesignTokens.standardPadding),
            child: submissionState.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              orElse: () => HaccpLongPressButton(
                label: formState.isValid ? 'ZATWIERDŹ CHECKLISTĘ' : 'UZUPEŁNIJ POLA',
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
    final success = await ref.read(ghpFormSubmissionProvider.notifier).submitChecklist(
      formId: formId,
      data: state.values,
    );

    if (success && context.mounted) {
      await HaccpSuccessOverlay.show(context);
      if (context.mounted) context.pop();
    } else if (!success && context.mounted) {
      final error = ref.read(ghpFormSubmissionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd zapisu: $error'),
          backgroundColor: HaccpDesignTokens.error,
        ),
      );
    }
  }

  String _getCategoryName(String id) {
    switch(id) {
      case 'personnel': return 'Personel';
      case 'rooms': return 'Pomieszczenia';
      case 'maintenance': return 'Konserwacja';
      case 'chemicals': return 'Chemia';
      default: return id;
    }
  }
}

  String _getCategoryName(String id) {
    switch(id) {
      case 'personnel': return 'Personel';
      case 'rooms': return 'Pomieszczenia';
      case 'maintenance': return 'Konserwacja';
      case 'chemicals': return 'Chemia';
      default: return id;
    }
  }
}
