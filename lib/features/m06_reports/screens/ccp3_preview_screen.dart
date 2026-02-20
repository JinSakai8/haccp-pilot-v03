import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/core/services/file_opener.dart';
import 'package:haccp_pilot/core/services/app_logger.dart';

final ccp3ReportProvider = FutureProvider.family<Uint8List?, DateTime>((ref, date) async {
  AppLogger.debug('🔵 CCP3 Provider: START for date=$date');
  
  try {
    final repo = ref.read(reportsRepositoryProvider);
    final user = ref.read(currentUserProvider);
    AppLogger.debug('🔵 CCP3 Provider: user=${user?.fullName ?? "NULL"}');
    
    String? venueId;
    try {
      final zones = await ref.watch(employeeZonesProvider.future);
      venueId = zones.isNotEmpty ? zones.first.venueId : null;
      AppLogger.debug('🔵 CCP3 Provider: zones=${zones.length}, venueId=$venueId');
    } catch (e) {
      AppLogger.debug('🔴 CCP3 Provider: employeeZones FAILED: $e');
    }

    // 1. Try to fetch saved report first (Cache)
    if (venueId != null) {
      try {
        final savedMetadata = await repo.getSavedReport(date, 'ccp3_cooling');
        AppLogger.debug('🔵 CCP3 Provider: savedMetadata=${savedMetadata != null ? "FOUND" : "NULL"}');
        if (savedMetadata != null) {
           final path = savedMetadata['storage_path'];
           final bytes = await repo.downloadReport(path);
           if (bytes != null) {
             AppLogger.debug('🟢 CCP3 Provider: Loaded from cache, ${bytes.length} bytes');
             return bytes;
           }
        }
      } catch (e) {
        AppLogger.debug('🟡 CCP3 Provider: Cache lookup failed (non-fatal): $e');
      }
    }

    // 2. If not found in cache, generate new
    AppLogger.debug('🔵 CCP3 Provider: Fetching cooling logs...');
    final logs = await repo.getCoolingLogs(date);
    AppLogger.debug('🔵 CCP3 Provider: getCoolingLogs returned ${logs.length} logs');
    
    if (logs.isEmpty) {
      AppLogger.debug('🟡 CCP3 Provider: No logs found → returning null');
      return null;
    }

    // Log first entry for debugging
    AppLogger.debug('🔵 CCP3 Provider: First log data keys: ${(logs.first['data'] as Map?)?.keys.toList()}');

    final userName = user?.fullName ?? 'Użytkownik';
    
    final pdfService = PdfService();
    AppLogger.debug('🔵 CCP3 Provider: Generating PDF...');
    final bytes = await pdfService.generateCcp3Report(
      logs: logs,
      userName: userName,
      date: date.toIso8601String().split('T')[0],
      venueLogo: null, 
    );
    AppLogger.debug('🟢 CCP3 Provider: PDF generated, ${bytes.length} bytes');
    
    // 3. Persist (Auto-save) — non-blocking, errors won't break display
    if (venueId != null && user != null && bytes.isNotEmpty) {
       try {
         final dateStr = date.toIso8601String().split('T')[0];
         final year = date.year.toString();
         final month = date.month.toString().padLeft(2, '0');
         final fileName = 'ccp3_cooling_$dateStr.pdf';
         final storagePath = '$venueId/$year/$month/$fileName';
         
         final uploadedPath = await repo.uploadReport(storagePath, bytes);
         
         if (uploadedPath != null) {
            await repo.saveReportMetadata(
               venueId: venueId,
               reportType: 'ccp3_cooling',
               generationDate: date,
               storagePath: uploadedPath,
               userId: user.id,
               metadata: {'generated_automatically': true},
            );
            AppLogger.debug('🟢 CCP3 Provider: Report persisted to $uploadedPath');
         }
       } catch (e) {
         AppLogger.debug('🟡 CCP3 Provider: Persistence failed (non-fatal): $e');
       }
    }

    return bytes;
  } catch (e, stackTrace) {
    AppLogger.debug('🔴 CCP3 Provider: FATAL ERROR: $e');
    AppLogger.debug('🔴 Stack: $stackTrace');
    rethrow;
  }
});

class Ccp3PreviewScreen extends ConsumerWidget {
  final DateTime date;

  const Ccp3PreviewScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfAsync = ref.watch(ccp3ReportProvider(date));

    return Scaffold(
      appBar: HaccpTopBar(
        title: 'Podgląd Raportu CCP-3',
        actions: [
          pdfAsync.when(
            data: (bytes) => IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                 // Share logic specific to bytes
               if (bytes != null) {
                 final file = XFile.fromData(bytes, name: 'CCP3_Raport.pdf', mimeType: 'application/pdf');
                 await Share.shareXFiles([file], text: 'Raport Chłodzenia');
               }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_,__) => const SizedBox.shrink(),
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: pdfAsync.when(
        data: (bytes) {
          if (bytes == null) {
            AppLogger.debug('🟡 CCP3 Screen: bytes == null → showing empty state');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text(
                    'Brak raportów chłodzenia\ndla wybranego dnia',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wypełnij formularz Chłodzenia Żywności,\naby wygenerować raport.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          AppLogger.debug('🟢 CCP3 Screen: Rendering PDF, ${bytes.length} bytes');
          return Column(
            children: [
              // Debug info bar (visible during development)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.green.withOpacity(0.15),
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
                        openFileFromBytes(bytes, 'CCP3_Raport.pdf');
                      },
                    ),
                  ],
                ),
              ),
              // PDF Viewer
              Expanded(
                child: SfPdfViewer.memory(bytes),
              ),
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
          AppLogger.debug('🔴 CCP3 Screen: ERROR: $err\n$stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Błąd generowania raportu',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

