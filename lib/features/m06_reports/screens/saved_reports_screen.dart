import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';

final savedReportsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final zones = await ref.watch(employeeZonesProvider.future);
      final venueId = zones.isNotEmpty ? zones.first.venueId : null;

      if (venueId == null) return [];

      final repo = ref.read(reportsRepositoryProvider);
      return repo.getGeneratedReports(venueId);
    });

bool _looksLikePdf(Uint8List bytes) {
  if (bytes.length < 4) return false;
  return bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46; // F
}

class SavedReportsScreen extends ConsumerWidget {
  const SavedReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(savedReportsProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Archiwum Raportów'),
      backgroundColor: AppTheme.background,
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'Brak zapisanych raportów',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportTile(report: report);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Błąd: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends ConsumerWidget {
  final Map<String, dynamic> report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = report['generation_date'] as String;
    final type = report['report_type'] as String;
    final createdAt = DateTime.parse(report['created_at'] as String);

    String label = type;
    if (type == 'ccp3_cooling') {
      label = 'Schładzanie (CCP-3)';
    } else if (type == 'ccp2_roasting') {
      label = 'Pieczenie (CCP-2)';
    } else if (type == 'waste_monthly') {
      label = 'Odpady (Miesięczny)';
    } else if (type == 'ccp1_temperature') {
      label = 'Temperatura (CCP-1)';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.picture_as_pdf, color: AppTheme.primary),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Okres: $dateStr',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Utworzono: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.download, color: Colors.grey),
        onTap: () async {
          final path = report['storage_path']?.toString();
          if (path == null || path.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Brak ścieżki storage dla raportu.'),
              ),
            );
            return;
          }

          final repo = ref.read(reportsRepositoryProvider);
          final bytes = await repo.downloadReport(path);
          if (bytes == null || bytes.isEmpty || !_looksLikePdf(bytes)) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Raport jest uszkodzony lub nie jest PDF.'),
                ),
              );

              if (type == 'ccp2_roasting') {
                final date = DateTime.tryParse(dateStr);
                if (date != null) {
                  context.push('/reports/preview/ccp2?date=$dateStr');
                }
              }
            }
            return;
          }

          final fileName = _buildFileName(type, dateStr, report['metadata']);
          ref.read(pdfServiceProvider).openFile(bytes, fileName);
        },
      ),
    );
  }

  String _buildFileName(String type, String date, dynamic metadata) {
    if (type == 'ccp1_temperature') {
      final sensorId = metadata is Map<String, dynamic>
          ? metadata['sensor_id']?.toString() ?? 'sensor'
          : 'sensor';
      final month = metadata is Map<String, dynamic>
          ? metadata['month']?.toString() ?? date
          : date;
      return 'ccp1_temperature_${sensorId}_$month.pdf';
    }
    return '$type-$date.pdf';
  }
}
