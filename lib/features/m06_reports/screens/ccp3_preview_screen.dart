import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/services/file_opener.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';

bool _looksLikePdf(Uint8List bytes) {
  if (bytes.length < 4) return false;
  return bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46; // F
}

String _monthLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

DateTime _monthEnd(DateTime date) =>
    DateTime(date.year, date.month + 1, 1).subtract(const Duration(milliseconds: 1));

@immutable
class Ccp3ReportRequest {
  final DateTime date;
  final bool forceRegenerate;

  const Ccp3ReportRequest({required this.date, this.forceRegenerate = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ccp3ReportRequest &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.forceRegenerate == forceRegenerate;
  }

  @override
  int get hashCode => Object.hash(date.year, date.month, forceRegenerate);
}

final ccp3ReportProvider =
    FutureProvider.family<Uint8List?, Ccp3ReportRequest>((ref, request) async {
      try {
        final repo = ref.read(reportsRepositoryProvider);
        final user = ref.read(currentUserProvider);
        final date = request.date;

        final currentZone = ref.read(currentZoneProvider);
        final zoneId = currentZone?.id;
        String? venueId = currentZone?.venueId;

        if (venueId == null) {
          try {
            final zones = await ref.watch(employeeZonesProvider.future);
            venueId = zones.isNotEmpty ? zones.first.venueId : null;
          } catch (_) {
            // Non-fatal.
          }
        }

        final periodStart = _monthStart(date);
        final periodEnd = _monthEnd(date);
        final monthLabel = _monthLabel(date);

        if (venueId != null && !request.forceRegenerate) {
          try {
            final savedMetadata = await repo.getSavedReport(
              periodStart,
              'ccp3_cooling',
              venueId: venueId,
            );
            if (savedMetadata != null) {
              final path = savedMetadata['storage_path']?.toString();
              if (path != null && path.isNotEmpty) {
                final bytes = await repo.downloadReport(path);
                if (bytes != null && _looksLikePdf(bytes)) {
                  return bytes;
                }
              }
            }
          } catch (_) {
            // Non-fatal.
          }
        }

        final logs = await repo.getCoolingLogs(
          periodStart,
          zoneId: zoneId,
          venueId: venueId,
        );

        if (logs.isEmpty) {
          return null;
        }

        final userName = user?.fullName ?? 'Użytkownik';
        final pdfService = PdfService();
        final bytes = await pdfService.generateCcp3Report(
          logs: logs,
          userName: userName,
          date: monthLabel,
          venueLogo: null,
        );

        if (venueId != null && user != null && bytes.isNotEmpty) {
          try {
            final year = date.year.toString();
            final month = date.month.toString().padLeft(2, '0');
            final fileName = 'ccp3_cooling_$monthLabel.pdf';
            final storagePath = '$venueId/$year/$month/$fileName';

            final uploadedPath = await repo.uploadReport(storagePath, bytes);

            if (uploadedPath != null) {
              await repo.saveReportMetadata(
                venueId: venueId,
                reportType: 'ccp3_cooling',
                generationDate: periodStart,
                storagePath: uploadedPath,
                userId: user.id,
                periodStart: periodStart,
                periodEnd: periodEnd,
                templateVersion: 'ccp3_pdf_v2',
                sourceFormId: 'food_cooling',
                metadata: {'generated_automatically': true},
              );
            }
          } catch (_) {
            // Non-fatal.
          }
        }

        return bytes;
      } catch (e, stackTrace) {
        debugPrint('CCP3 Provider fatal error: $e');
        debugPrint('CCP3 Provider stack: $stackTrace');
        rethrow;
      }
    });

class Ccp3PreviewScreen extends ConsumerWidget {
  final DateTime date;
  final bool forceRegenerate;

  const Ccp3PreviewScreen({
    super.key,
    required this.date,
    this.forceRegenerate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfAsync = ref.watch(
      ccp3ReportProvider(
        Ccp3ReportRequest(date: date, forceRegenerate: forceRegenerate),
      ),
    );
    final monthLabel = _monthLabel(date);

    return Scaffold(
      appBar: HaccpTopBar(
        title: 'Podgląd Raportu CCP-3',
        actions: [
          pdfAsync.when(
            data: (bytes) => IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                if (bytes != null) {
                  final file = XFile.fromData(
                    bytes,
                    name: 'CCP3_Raport_$monthLabel.pdf',
                    mimeType: 'application/pdf',
                  );
                  await Share.shareXFiles([file], text: 'Raport chłodzenia CCP-3');
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: pdfAsync.when(
        data: (bytes) {
          if (bytes == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text(
                    'Brak raportów chłodzenia\ndla wybranego miesiąca',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wypełnij formularz Chłodzenia żywności,\naby wygenerować raport.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.green.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'PDF załadowany: ${bytes.length} bajtów',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Pobierz', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        openFileFromBytes(bytes, 'CCP3_Raport_$monthLabel.pdf');
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: SfPdfViewer.memory(bytes)),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generowanie raportu...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        error: (err, stack) {
          debugPrint('CCP3 Screen ERROR: $err\n$stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Błąd generowania raportu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
