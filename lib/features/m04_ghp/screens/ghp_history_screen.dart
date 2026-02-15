import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/design_tokens.dart';
import '../providers/ghp_provider.dart';

class GhpHistoryScreen extends ConsumerWidget {
  const GhpHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(ghpHistoryProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Historia GHP'),
      body: historyAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const HaccpEmptyState(
              headline: "Brak wpisów GHP",
              subtext: "Brak zakończonych checklist higieny w tej strefie.",
              icon: Icons.history,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _GhpLogCard(log: log);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd: $err')),
      ),
    );
  }
}

class _GhpLogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _GhpLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(log['created_at']);
    final formId = log['form_id'] as String;
    
    // Map formId to readable name
    String title = formId.toUpperCase();
    if (formId.contains('personnel')) title = 'HIGIENA PERSONELU';
    if (formId.contains('rooms')) title = 'HIGIENA POMIESZCZEŃ';
    if (formId.contains('maintenance')) title = 'KONSERWACJA';
    if (formId.contains('chemicals')) title = 'ŚRODKI CZYSTOŚCI';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: HaccpDesignTokens.primary.withOpacity(0.2),
          child: const Icon(Icons.check_circle, color: HaccpDesignTokens.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
        // trailing: const Icon(Icons.chevron_right), // Details view could be added later
      ),
    );
  }
}
