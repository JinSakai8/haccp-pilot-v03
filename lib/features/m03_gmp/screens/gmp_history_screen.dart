import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/haccp_top_bar.dart';
import '../providers/gmp_provider.dart';

class GmpHistoryScreen extends ConsumerWidget {
  const GmpHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(gmpHistoryProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Historia GMP'),
      body: historyAsync.when(
        data: (logs) => logs.isEmpty
            ? const Center(child: Text('Brak wpisów GMP'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final date = DateTime.parse(log['created_at']);
                  return Card(
                    child: ListTile(
                      title: Text(log['form_id']?.replaceAll('_', ' ').toUpperCase() ?? 'RAPORT'),
                      subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd: $err')),
      ),
    );
  }
}
