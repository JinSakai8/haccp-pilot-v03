import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/haccp_date_picker.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/design_tokens.dart';
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

  // Manual list of processes for filtering
  final Map<String, String> _processTypes = {
    'meat_roasting': 'Obróbka Termiczna',
    'food_cooling': 'Schładzanie',
    'delivery_control': 'Dostawa',
  };

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(gmpHistoryProvider(
      fromDate: _fromDate,
      toDate: _toDate,
      formId: _selectedFormId,
    ));

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Historia GMP'),
      body: Column(
        children: [
          // Filters Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: Text(_fromDate == null ? 'Od: Kiedykolwiek' : 'Od: ${DateFormat('MM-dd').format(_fromDate!)}'),
                        onPressed: () => _pickDate(true),
                        backgroundColor: _fromDate != null ? HaccpDesignTokens.primary.withOpacity(0.2) : null,
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: Text(_toDate == null ? 'Do: Dzisiaj' : 'Do: ${DateFormat('MM-dd').format(_toDate!)}'),
                        onPressed: () => _pickDate(false),
                         backgroundColor: _toDate != null ? HaccpDesignTokens.primary.withOpacity(0.2) : null,
                      ),
                      const SizedBox(width: 8),
                      if (_fromDate != null || _toDate != null)
                        IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () {
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                          });
                        }),
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
                      headline: "Brak wyników",
                      subtext: "Nie znaleziono wpisów dla wybranych filtrów.",
                      icon: Icons.filter_list_off,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final date = DateTime.parse(log['created_at']);
                        final formId = log['form_id'] as String;
                        final label = _processTypes[formId] ?? formId.toUpperCase();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(label),
                            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Details view logic
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
