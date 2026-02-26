import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_tokens.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../config/gmp_form_ids.dart';
import '../providers/gmp_provider.dart';

class GmpHistoryScreen extends ConsumerStatefulWidget {
  const GmpHistoryScreen({super.key});

  @override
  ConsumerState<GmpHistoryScreen> createState() => _GmpHistoryScreenState();
}

class _GmpHistoryScreenState extends ConsumerState<GmpHistoryScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedFormId;

  final Map<String, String> _processTypes = gmpProcessLabels;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      gmpHistoryProvider(
        fromDate: _fromDate,
        toDate: _toDate,
        formId: _selectedFormId,
      ),
    );

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Historia GMP'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: Text(
                          _fromDate == null
                              ? 'Od: Kiedykolwiek'
                              : 'Od: ${DateFormat('MM-dd').format(_fromDate!)}',
                        ),
                        onPressed: () => _pickDate(true),
                        backgroundColor: _fromDate != null
                            ? HaccpDesignTokens.primary.withValues(alpha: 0.2)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: Text(
                          _toDate == null
                              ? 'Do: Dzisiaj'
                              : 'Do: ${DateFormat('MM-dd').format(_toDate!)}',
                        ),
                        onPressed: () => _pickDate(false),
                        backgroundColor: _toDate != null
                            ? HaccpDesignTokens.primary.withValues(alpha: 0.2)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      if (_fromDate != null || _toDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _processTypes.entries.map((entry) {
                      final isSelected = _selectedFormId == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(entry.value),
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedFormId = selected ? entry.key : null;
                            });
                          },
                          selectedColor: HaccpDesignTokens.primary,
                          checkmarkColor: Colors.black,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              data: (logs) => logs.isEmpty
                  ? const HaccpEmptyState(
                      headline: 'Brak wyników',
                      subtext: 'Nie znaleziono wpisów dla wybranych filtrów.',
                      icon: Icons.filter_list_off,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final date = DateTime.parse(log['created_at'] as String);
                        final logData = log['data'] as Map<String, dynamic>? ?? {};
                        final rawFormId = log['form_id'] as String;
                        final normalizedFormId = normalizeGmpFormId(rawFormId);
                        final label =
                            _processTypes[normalizedFormId] ?? normalizedFormId.toUpperCase();

                        Widget statusIcon = const SizedBox.shrink();
                        if (logData.containsKey('is_compliant') ||
                            logData.containsKey('compliance')) {
                          final isCompliant =
                              logData['is_compliant'] ?? logData['compliance'];
                          if (isCompliant == true) {
                            statusIcon = const Icon(
                              Icons.check_circle,
                              color: HaccpDesignTokens.success,
                              size: 20,
                            );
                          } else if (isCompliant == false) {
                            statusIcon = const Icon(
                              Icons.warning,
                              color: HaccpDesignTokens.warning,
                              size: 20,
                            );
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.history),
                            title: Row(
                              children: [
                                Expanded(child: Text(label)),
                                const SizedBox(width: 8),
                                statusIcon,
                              ],
                            ),
                            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              final previewRoute = gmpHistoryPreviewRoute(
                                rawFormId: rawFormId,
                                anchorDate: date,
                              );
                              if (previewRoute != null) {
                                context.push(previewRoute);
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(gmpHistoryPreviewUnavailableMessage),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Błąd: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: HaccpDesignTokens.primary,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked.add(const Duration(hours: 23, minutes: 59));
        }
      });
    }
  }
}
