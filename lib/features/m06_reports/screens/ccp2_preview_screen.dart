import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/services/file_opener.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';

const bool _ccp2DebugLogs = bool.fromEnvironment(
  'HACCP_REPORTS_DEBUG',
  defaultValue: false,
);

void _ccp2Log(String message) {
  if (_ccp2DebugLogs) {
    debugPrint('[CCP2] $message');
  }
}

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

DateTime _monthEnd(DateTime date) => DateTime(
  date.year,
  date.month + 1,
  1,
).subtract(const Duration(milliseconds: 1));

@visibleForTesting
Ccp2ReportRow mapHaccpLogToCcp2ReportRow(Map<String, dynamic> raw) {
  final data = (raw['data'] as Map?)?.cast<String, dynamic>() ?? const {};

  final createdAtRaw = raw['created_at']?.toString();
  DateTime? createdAt;
  if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
    createdAt = DateTime.tryParse(createdAtRaw);
  }

  String dateLabel = '-';
  final prepDateRaw = data['prep_date']?.toString();
  if (prepDateRaw != null && prepDateRaw.isNotEmpty) {
    final prepDate = DateTime.tryParse(prepDateRaw);
    if (prepDate != null) {
      final day = prepDate.day.toString().padLeft(2, '0');
      final month = prepDate.month.toString().padLeft(2, '0');
      final year = prepDate.year.toString();
      dateLabel = '$day.$month.$year';
    }
  } else if (createdAt != null) {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    dateLabel = '$day.$month.$year';
  }

  final productName = data['product_name']?.toString() ?? '-';
  final tempRaw = data['temperature'] ?? data['internal_temp'];
  final temperature = tempRaw?.toString() ?? '-';

  bool isCompliant;
  if (data.containsKey('is_compliant')) {
    isCompliant = data['is_compliant'] == true;
  } else if (data.containsKey('compliance')) {
    isCompliant = data['compliance'] == true;
  } else {
    final parsed = double.tryParse(
      temperature.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    isCompliant = parsed != null ? parsed >= 90.0 : true;
  }

  final correctiveActions =
      data['corrective_actions']?.toString() ??
      data['comments']?.toString() ??
      '';
  final signature = data['signature']?.toString() ?? '';

  return Ccp2ReportRow(
    dateTime: dateLabel,
    productName: productName,
    temperature: temperature,
    isCompliant: isCompliant,
    correctiveActions: correctiveActions,
    signature: signature,
  );
}

final ccp2ReportProvider = FutureProvider.family<Uint8List?, DateTime>((
  ref,
  date,
) async {
  try {
    final repo = ref.read(reportsRepositoryProvider);
    final user = ref.read(currentUserProvider);

    final currentZone = ref.read(currentZoneProvider);
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

    if (venueId != null) {
      try {
        final savedMetadata = await repo.getSavedReport(
          periodStart,
          'ccp2_roasting',
          venueId: venueId,
        );
        if (savedMetadata != null) {
          final path = savedMetadata['storage_path']?.toString();
          if (path != null && path.isNotEmpty) {
            final bytes = await repo.downloadReport(path);
            if (bytes != null && _looksLikePdf(bytes)) {
              return bytes;
            }
            _ccp2Log('cached report is not a valid PDF, regenerate');
          }
        }
      } catch (e) {
        _ccp2Log('cache lookup failed: $e');
      }
    }

    final logs = await repo.getRoastingLogs(
      periodStart,
      zoneId: null,
      venueId: venueId,
    );
    if (logs.isEmpty) {
      return null;
    }

    final rows = logs.map(mapHaccpLogToCcp2ReportRow).toList();
    final userName = user?.fullName ?? 'Uzytkownik';
    final venueProfile = venueId != null
        ? await repo.getVenueProfile(venueId)
        : null;
    final venueName = venueProfile?['name']?.toString() ?? 'Lokal';
    final venueAddress = venueProfile?['address']?.toString();
    final venueLogo = venueId != null ? await repo.getVenueLogo(venueId) : null;

    final pdfService = PdfService();
    final bytes = await pdfService.generateCcp2Report(
      rows: rows,
      userName: userName,
      monthLabel: monthLabel,
      venueName: venueName,
      venueAddress: venueAddress,
      venueLogo: venueLogo,
    );

    if (venueId != null && user != null && bytes.isNotEmpty) {
      try {
        final year = date.year.toString();
        final month = date.month.toString().padLeft(2, '0');
        final fileName = 'ccp2_roasting_$monthLabel.pdf';
        final storagePath = '$venueId/$year/$month/$fileName';
        final uploadedPath = await repo.uploadReport(storagePath, bytes);

        if (uploadedPath != null) {
          await repo.saveReportMetadata(
            venueId: venueId,
            reportType: 'ccp2_roasting',
            generationDate: periodStart,
            storagePath: uploadedPath,
            userId: user.id,
            periodStart: periodStart,
            periodEnd: periodEnd,
            templateVersion: 'ccp2_pdf_v2',
            sourceFormId: 'meat_roasting',
            metadata: {'generated_automatically': true},
          );
        }
      } catch (e) {
        _ccp2Log('persist failed: $e');
      }
    }

    return bytes;
  } catch (e, stackTrace) {
    debugPrint('CCP2 Provider fatal error: $e');
    debugPrint('CCP2 Provider stack: $stackTrace');
    rethrow;
  }
});

class Ccp2PreviewScreen extends ConsumerWidget {
  final DateTime date;

  const Ccp2PreviewScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfAsync = ref.watch(ccp2ReportProvider(date));
    final monthLabel = _monthLabel(date);

    return Scaffold(
      appBar: HaccpTopBar(
        title: 'Podglad Raportu CCP-2',
        actions: [
          pdfAsync.when(
            data: (bytes) => IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                if (bytes != null) {
                  final file = XFile.fromData(
                    bytes,
                    name: 'CCP2_Raport_$monthLabel.pdf',
                    mimeType: 'application/pdf',
                  );
                  await Share.shareXFiles([
                    file,
                  ], text: 'Raport pieczenia CCP-2');
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
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Brak raportow pieczenia\ndla wybranego miesiaca',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wypelnij formularz Pieczenia Mies,\naby wygenerowac raport.',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.green.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PDF zaladowany: ${bytes.length} bajtow',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text(
                        'Pobierz',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        openFileFromBytes(bytes, 'CCP2_Raport_$monthLabel.pdf');
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
              Text(
                'Generowanie raportu...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        error: (err, stack) {
          debugPrint('CCP2 Screen ERROR: $err\n$stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Blad generowania raportu',
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
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Wroc'),
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
