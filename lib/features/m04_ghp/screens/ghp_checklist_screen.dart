import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/haccp_long_press_button.dart';
import '../../../core/widgets/haccp_top_bar.dart';
import '../../../core/widgets/success_overlay.dart';
import '../../shared/config/checklist_definitions.dart';
import '../../shared/providers/dynamic_form_provider.dart';
import '../../shared/widgets/dynamic_form/dynamic_form_renderer.dart';
import '../providers/ghp_provider.dart';

class GhpChecklistScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const GhpChecklistScreen({super.key, required this.categoryId});

  @override
  ConsumerState<GhpChecklistScreen> createState() => _GhpChecklistScreenState();
}

class _GhpChecklistScreenState extends ConsumerState<GhpChecklistScreen> {
  DateTime? _executionDate;
  TimeOfDay? _executionTime;

  @override
  void initState() {
    super.initState();
    _executionDate = null;
    _executionTime = null;
  }

  @override
  Widget build(BuildContext context) {
    final definition = ChecklistDefinitions.ghpDefinitions[widget.categoryId];

    if (definition == null) {
      return Scaffold(
        appBar: const HaccpTopBar(title: 'Blad'),
        body: Center(child: Text('Nieznana kategoria: ${widget.categoryId}')),
      );
    }

    final formId = 'ghp_${widget.categoryId}';
    final formState = ref.watch(dynamicFormProvider(formId, definition));
    final submissionState = ref.watch(ghpFormSubmissionProvider);
    final hasExecutionDateTime =
        _executionDate != null && _executionTime != null;
    final canSubmit = formState.isValid && hasExecutionDateTime;

    return Scaffold(
      appBar: HaccpTopBar(
        title: 'Checklista: ${_getCategoryName(widget.categoryId)}',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _ExecutionDateTimeCard(
              executionDate: _executionDate,
              executionTime: _executionTime,
              onPickDate: _pickExecutionDate,
              onPickTime: _pickExecutionTime,
            ),
          ),
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
                label: canSubmit ? 'ZATWIERDZ CHECKLISTE' : 'UZUPELNIJ POLA',
                color: canSubmit ? HaccpDesignTokens.success : Colors.grey,
                onCompleted: canSubmit
                    ? () => _handleSubmit(context, formState, formId)
                    : () => _showValidationError(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExecutionDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _executionDate ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: now,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _executionDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  Future<void> _pickExecutionTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _executionTime ?? TimeOfDay.now(),
    );
    if (selected == null || !mounted) return;
    setState(() => _executionTime = selected);
  }

  Future<void> _handleSubmit(
    BuildContext context,
    DynamicFormState state,
    String formId,
  ) async {
    if (_executionDate == null || _executionTime == null) {
      _showValidationError(context);
      return;
    }

    final executionDate = DateFormat('yyyy-MM-dd').format(_executionDate!);
    final executionTime =
        '${_executionTime!.hour.toString().padLeft(2, '0')}:${_executionTime!.minute.toString().padLeft(2, '0')}';

    final success = await ref
        .read(ghpFormSubmissionProvider.notifier)
        .submitChecklist(
          formId: formId,
          data: {
            'execution_date': executionDate,
            'execution_time': executionTime,
            'answers': state.values,
          },
        );

    if (success && context.mounted) {
      await HaccpSuccessOverlay.show(context);
      if (context.mounted) context.pop();
    } else if (!success && context.mounted) {
      final error = ref.read(ghpFormSubmissionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blad zapisu: $error'),
          backgroundColor: HaccpDesignTokens.error,
        ),
      );
    }
  }

  void _showValidationError(BuildContext context) {
    final message = (_executionDate == null || _executionTime == null)
        ? 'Wybierz date i godzine wykonania checklisty.'
        : 'Prosze uzupelnic wszystkie wymagane pola.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getCategoryName(String id) {
    switch (id) {
      case 'personnel':
        return 'Personel';
      case 'rooms':
        return 'Pomieszczenia';
      case 'maintenance':
        return 'Konserwacja';
      case 'chemicals':
        return 'Chemia';
      default:
        return id;
    }
  }
}

class _ExecutionDateTimeCard extends StatelessWidget {
  final DateTime? executionDate;
  final TimeOfDay? executionTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _ExecutionDateTimeCard({
    required this.executionDate,
    required this.executionTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = executionDate == null
        ? 'Wybierz date'
        : DateFormat('yyyy-MM-dd').format(executionDate!);
    final timeLabel = executionTime == null
        ? 'Wybierz godzine'
        : '${executionTime!.hour.toString().padLeft(2, '0')}:${executionTime!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(dateLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickTime,
              icon: const Icon(Icons.access_time),
              label: Text(timeLabel),
            ),
          ),
        ],
      ),
    );
  }
}
