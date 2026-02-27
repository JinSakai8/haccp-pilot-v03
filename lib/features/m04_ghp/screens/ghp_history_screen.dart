import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_tokens.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../providers/ghp_provider.dart';

class GhpHistoryScreen extends ConsumerStatefulWidget {
  const GhpHistoryScreen({super.key});

  @override
  ConsumerState<GhpHistoryScreen> createState() => _GhpHistoryScreenState();
}

class _GhpHistoryScreenState extends ConsumerState<GhpHistoryScreen> {
  String _selectedCategory = 'all';
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(ghpHistoryProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Historia GHP'),
      body: historyAsync.when(
        data: (logs) {
          final filteredLogs = logs.where(_matchesFilters).toList();
          if (filteredLogs.isEmpty) {
            return const HaccpEmptyState(
              headline: 'Brak wpisow GHP',
              subtext: 'Brak wpisow dla wybranych filtrow.',
              icon: Icons.history,
            );
          }

          return Column(
            children: [
              _HistoryFilters(
                selectedCategory: _selectedCategory,
                selectedDate: _selectedDate,
                onCategoryChanged: (value) =>
                    setState(() => _selectedCategory = value),
                onDateTap: _pickDate,
                onClearDate: () => setState(() => _selectedDate = null),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return _GhpLogCard(
                      log: log,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GhpHistoryDetailsScreen(log: log),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Blad: $err')),
      ),
    );
  }

  bool _matchesFilters(Map<String, dynamic> log) {
    final formId = (log['form_id']?.toString() ?? '').toLowerCase();
    if (_selectedCategory != 'all' && !formId.contains(_selectedCategory)) {
      return false;
    }

    if (_selectedDate == null) return true;
    final data = (log['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final executionDateRaw = data['execution_date']?.toString();
    final createdAtRaw = log['created_at']?.toString();
    DateTime? day;
    if (executionDateRaw != null && executionDateRaw.isNotEmpty) {
      day = DateTime.tryParse(executionDateRaw);
    }
    day ??= createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;
    if (day == null) return false;
    return day.year == _selectedDate!.year &&
        day.month == _selectedDate!.month &&
        day.day == _selectedDate!.day;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: now,
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
  }
}

class _HistoryFilters extends StatelessWidget {
  final String selectedCategory;
  final DateTime? selectedDate;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;

  const _HistoryFilters({
    required this.selectedCategory,
    required this.selectedDate,
    required this.onCategoryChanged,
    required this.onDateTap,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategoria',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
                DropdownMenuItem(value: 'personnel', child: Text('Personel')),
                DropdownMenuItem(value: 'rooms', child: Text('Pomieszczenia')),
                DropdownMenuItem(
                  value: 'maintenance',
                  child: Text('Konserwacja'),
                ),
                DropdownMenuItem(value: 'chemicals', child: Text('Chemia')),
              ],
              onChanged: (value) => onCategoryChanged(value ?? 'all'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onDateTap,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              selectedDate == null
                  ? 'Data'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!),
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Wyczysc date',
              onPressed: onClearDate,
            ),
          ],
        ],
      ),
    );
  }
}

class _GhpLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onTap;

  const _GhpLogCard({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final data = (log['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final createdAt = DateTime.tryParse(log['created_at']?.toString() ?? '');
    final executionDate = data['execution_date']?.toString();
    final executionTime = data['execution_time']?.toString();

    final createdAtLabel = createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt)
        : '-';
    final executionLabel = '${executionDate ?? '-'} ${executionTime ?? ''}'
        .trim();
    final title = _readableTitle(log['form_id']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: HaccpDesignTokens.primary.withValues(alpha: 0.2),
          child: const Icon(
            Icons.check_circle,
            color: HaccpDesignTokens.primary,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wykonano: $executionLabel'),
            Text('Wpis utworzono: $createdAtLabel'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _readableTitle(String formId) {
    if (formId.contains('personnel')) return 'HIGIENA PERSONELU';
    if (formId.contains('rooms')) return 'HIGIENA POMIESZCZEN';
    if (formId.contains('maintenance')) return 'KONSERWACJA';
    if (formId.contains('chemicals')) return 'SRODKI CZYSTOSCI';
    return formId.toUpperCase();
  }
}

class GhpHistoryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> log;

  const GhpHistoryDetailsScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final data = (log['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final answers = data['answers'] is Map
        ? Map<String, dynamic>.from(data['answers'] as Map)
        : <String, dynamic>{};
    final notes = data['notes']?.toString();
    final createdAt = DateTime.tryParse(log['created_at']?.toString() ?? '');

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Szczegoly wpisu GHP'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailsSection(
            title: 'Metadane',
            children: [
              _detailsRow('Kategoria', log['form_id']?.toString() ?? '-'),
              _detailsRow(
                'Wykonawca (user_id)',
                log['user_id']?.toString() ?? '-',
              ),
              _detailsRow(
                'Data wykonania',
                data['execution_date']?.toString() ?? '-',
              ),
              _detailsRow(
                'Godzina wykonania',
                data['execution_time']?.toString() ?? '-',
              ),
              _detailsRow(
                'Czas utworzenia wpisu',
                createdAt != null
                    ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt)
                    : '-',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailsSection(
            title: 'Wartosci checklisty',
            children: answers.isEmpty
                ? [const Text('Brak zapisanych odpowiedzi.')]
                : answers.entries
                      .map(
                        (entry) =>
                            _detailsRow(entry.key, _formatValue(entry.value)),
                      )
                      .toList(),
          ),
          if (notes != null && notes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailsSection(
              title: 'Komentarz / Uwagi',
              children: [Text(notes)],
            ),
          ],
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is bool) return value ? 'TAK' : 'NIE';
    return value?.toString() ?? '-';
  }

  Widget _detailsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
