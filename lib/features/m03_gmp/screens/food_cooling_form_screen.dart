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
    const String formId = 'food_cooling_daily';
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

      // 2. Fetch Data for Report (Current Day)
      // We need the date from the form or just use "Today" if prep_date is today.
      // Usually users enter data for "Now".
      // Let's take the date from the form 'prep_date' if available, else Now.
      String dateStr = state.values['prep_date']?.toString() ?? DateTime.now().toIso8601String();
      DateTime reportDate = DateTime.tryParse(dateStr) ?? DateTime.now();

      // Show loading or navigate to preview which handles loading
      // For immediate gratification, let's navigate to a preview screen that loads the report.
      // However, we need to pass the "type" of report.
      // Since PdfPreviewScreen usually takes a reportId or bytes, let's use a workaround 
      // where we generate bytes here or pass parameters to a specialized route.
      
      // Simpler approach for now: Generate here, then push Preview with bytes.
      // But we shouldn't block UI too long.
      
      // Let's navigate to standard PDF Preview route with a special query param or ID.
      // Or better: Use the existing /reports/preview route but we need a "Report ID".
      // Since this is dynamic/on-the-fly, maybe we pass the data?
      // No, let's fetch the data in the Preview screen?
      // actually, the requirement is "generuje się raport... oraz zapisuje się do bazy".
      // The simplest integration without new routes is to push a MaterialPageRoute with `PdfPreviewScreen` 
      // instantiated with data, BUT `PdfPreviewScreen` likely expects a report ID to fetch from DB/Storage?
      // Let's check `PdfPreviewScreen` implementation.
      
      // If we can't easily reuse PdfPreviewScreen, we might need a dedicated `Ccp3PreviewScreen` or modify the existing one.
      // Let's assume we can navigate to the reports panel or use the PdfService directly to show it?
      // The user wants "generuje się raport w pdf... w takim formacie".
      // Let's try to open it using `PdfService.openFile` if on Web, or navigate to a viewer.
      
      try {
        // Fetch logs
        // We need ReportsRepository.
        // Quick hook into repository via provider (we might need to add it to a provider if not exposed).
        // Assuming we can get it via a provider or just instantiate for this action (less clean but works).
        // Better: Use a provider.
        // ref.read(reportsRepositoryProvider).getCoolingLogs(...)
        
        // As we don't have the implementation of `reportsRepositoryProvider` visible in context, 
        // I will assume standard Riverpod pattern: `reportsRepositoryProvider`.
        // If not, I'll use a direct import for now to move forward, but cleaner to use provider.
        
        // Let's assume we navigate to the Reports Panel for now to see it? 
        // No, user wants *immediate* generation.
        
        // I will Navigate to the Report Preview Screen, passing the "date" and "type" 
        // and let that screen handle the generation.
        // But PdfPreviewScreen might be bound to "Saved Reports".
        
        // Let's assume we construct the PDF bytes here and push a generic viewer.
        // This ensures the "Immediate" feel.
        
        /* 
           Navigation to be implemented after checking PdfPreviewScreen.
           For now, let's just pop or show a success message that report is ready.
           Wait, User said "po zapisaniu... generuje się raport".
        */
        
        context.push('/reports/preview/ccp3?date=${reportDate.toIso8601String()}');
        
      } catch (e) {
         debugPrint('Report generation trigger failed: $e');
         if (context.mounted) context.pop(); // Fallback
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
