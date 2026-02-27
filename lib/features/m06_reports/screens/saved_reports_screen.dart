import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';

final savedReportsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final currentZone = ref.watch(currentZoneProvider);
      String? venueId = currentZone?.venueId;

      if (venueId == null || venueId.isEmpty) {
        final zones = await ref.watch(employeeZonesProvider.future);
        venueId = zones.isNotEmpty ? zones.first.venueId : null;
      }

      if (venueId == null) return [];
      return ref.read(reportsRepositoryProvider).getGeneratedReports(venueId);
    });

bool _looksLikePdf(Uint8List bytes) {
  if (bytes.length < 4) return false;
  return bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

@visibleForTesting
String? buildFallbackPreviewRoute(String reportType, String dateStr) {
  if (DateTime.tryParse(dateStr) == null) return null;
  if (reportType == 'ccp2_roasting') {
    return '/reports/preview/ccp2?date=$dateStr&force=1';
  }
  if (reportType == 'ccp3_cooling') {
    return '/reports/preview/ccp3?date=$dateStr&force=1';
  }
  return null;
}

class SavedReportsScreen extends ConsumerWidget {
  const SavedReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(savedReportsProvider);

    return Scaffold(
      appBar: const HaccpTopBar(title: 'Archiwum raportow'),
      backgroundColor: AppTheme.background,
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'Brak zapisanych raportow',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _ReportTile(report: reports[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Blad: $err',
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
    final label = _labelForType(type);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Okres: $dateStr',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Utworzono: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleOpen(context, ref, report),
                    icon: const Icon(Icons.visibility),
                    label: const Text('PODGLAD'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                    ),
                    onPressed: () => _handleOpen(context, ref, report),
                    icon: const Icon(Icons.download),
                    label: const Text('POBIERZ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'ccp3_cooling':
        return 'Schladzanie (CCP-3)';
      case 'ccp2_roasting':
        return 'Pieczenie (CCP-2)';
      case 'waste_monthly':
        return 'Odpady (miesieczny)';
      case 'ccp1_temperature':
        return 'Temperatura (CCP-1)';
      case 'ghp_checklist_monthly':
        return 'Checklisty GHP (miesieczny)';
      default:
        return type;
    }
  }

  Future<void> _handleOpen(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> report,
  ) async {
    final dateStr = report['generation_date']?.toString() ?? '';
    final type = report['report_type']?.toString() ?? '';
    final path = report['storage_path']?.toString();
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak sciezki storage dla raportu.')),
      );
      return;
    }

    final repo = ref.read(reportsRepositoryProvider);
    final bytes = await repo.downloadReport(path);
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty || !_looksLikePdf(bytes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raport jest uszkodzony lub nie jest PDF.'),
        ),
      );
      _handleFallbackPreview(context, type, dateStr);
      return;
    }

    final fileName = _buildFileName(type, dateStr, report['metadata']);
    ref.read(pdfServiceProvider).openFile(bytes, fileName);
  }

  void _handleFallbackPreview(
    BuildContext context,
    String type,
    String dateStr,
  ) {
    if (!context.mounted) return;
    final route = buildFallbackPreviewRoute(type, dateStr);
    if (route == null) return;
    context.push(route);
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
    if (type == 'ghp_checklist_monthly') {
      final month = metadata is Map<String, dynamic>
          ? metadata['month']?.toString() ?? date
          : date;
      return 'ghp_checklist_$month.pdf';
    }
    return '$type-$date.pdf';
  }
}
