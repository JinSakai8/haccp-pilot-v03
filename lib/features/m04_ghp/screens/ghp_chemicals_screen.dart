import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_tokens.dart';
import '../../../../core/widgets/haccp_long_press_button.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../shared/config/checklist_definitions.dart';
import '../providers/ghp_provider.dart';

class GhpChemicalsScreen extends ConsumerStatefulWidget {
  const GhpChemicalsScreen({super.key});

  @override
  ConsumerState<GhpChemicalsScreen> createState() => _GhpChemicalsScreenState();
}

class _GhpChemicalsScreenState extends ConsumerState<GhpChemicalsScreen> {
  final List<String> _chemicals = ChecklistDefinitions.ghpChemicalsCatalog;
  final Map<String, double> _usage = {};

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
    final submissionState = ref.watch(ghpFormSubmissionProvider);
    final hasExecutionDateTime =
        _executionDate != null && _executionTime != null;

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Rejestr Chemii'),
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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _chemicals.length,
              separatorBuilder: (c, i) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final chemical = _chemicals[index];
                final currentVal = _usage[chemical] ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chemical,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (currentVal <= 0) return;
                                setState(() {
                                  _usage[chemical] = (currentVal - 0.5).clamp(
                                    0.0,
                                    100.0,
                                  );
                                });
                              },
                            ),
                            SizedBox(
                              width: 44,
                              child: Text(
                                currentVal.toStringAsFixed(1),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(
                                  () => _usage[chemical] = currentVal + 0.5,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: submissionState.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              orElse: () => HaccpLongPressButton(
                label: _hasUsage && hasExecutionDateTime
                    ? 'ZAPISZ ZUZYCIE'
                    : 'UZUPELNIJ DANE',
                color: _hasUsage && hasExecutionDateTime
                    ? HaccpDesignTokens.success
                    : Colors.grey,
                onCompleted: _hasUsage && hasExecutionDateTime
                    ? () => _submit(context)
                    : () => _showValidationError(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasUsage => _usage.values.any((v) => v > 0);

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

  Future<void> _submit(BuildContext context) async {
    if (_executionDate == null || _executionTime == null || !_hasUsage) {
      _showValidationError(context);
      return;
    }

    final executionDate = DateFormat('yyyy-MM-dd').format(_executionDate!);
    final executionTime =
        '${_executionTime!.hour.toString().padLeft(2, '0')}:${_executionTime!.minute.toString().padLeft(2, '0')}';
    final answers = Map<String, dynamic>.fromEntries(
      _usage.entries.where((entry) => entry.value > 0),
    );

    final success = await ref
        .read(ghpFormSubmissionProvider.notifier)
        .submitChecklist(
          formId: 'ghp_chemicals',
          data: {
            'execution_date': executionDate,
            'execution_time': executionTime,
            'answers': answers,
          },
        );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zapisano zuzycie chemii'),
          backgroundColor: HaccpDesignTokens.success,
        ),
      );
      setState(() => _usage.clear());
    }
  }

  void _showValidationError(BuildContext context) {
    final message = !_hasUsage
        ? 'Wprowadz zuzycie co najmniej jednego srodka.'
        : 'Wybierz date i godzine wykonania.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
