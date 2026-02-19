import 'dart:typed_data';
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

// reportsRepositoryProvider is now imported from reports_provider.dart

final ccp3ReportProvider = FutureProvider.family<Uint8List?, DateTime>((ref, date) async {
  final repo = ref.read(reportsRepositoryProvider);
  final user = ref.read(currentUserProvider);
  final zones = await ref.watch(employeeZonesProvider.future);
  final venueId = zones.isNotEmpty ? zones.first.venueId : null;

  // 1. Try to fetch saved report first (Cache)
  // Only if venueId is available
  if (venueId != null) {
      final savedMetadata = await repo.getSavedReport(date, 'ccp3_cooling');
      if (savedMetadata != null) {
         final path = savedMetadata['storage_path'];
         final bytes = await repo.downloadReport(path);
         if (bytes != null) return bytes;
      }
  }

  // 2. If not found, generate new
  final logs = await repo.getCoolingLogs(date);
  
  if (logs.isEmpty) return null; // Return null to signal empty state

  final userName = user?.fullName ?? 'Użytkownik';
  
  // Get Logo (if needed, implemented in repo but not used here yet)
  // Uint8List? logo = venueId != null ? await repo.getVenueLogo(venueId) : null;
  
  final pdfService = PdfService();
  final bytes = await pdfService.generateCcp3Report(
    logs: logs,
    userName: userName,
    date: date.toIso8601String().split('T')[0], // YYYY-MM-DD
    venueLogo: null, 
  );
  
  // 3. Persist (Auto-save)
  if (venueId != null && user != null && bytes.length > 0) {
     final dateStr = date.toIso8601String().split('T')[0];
     final year = date.year.toString();
     final month = date.month.toString().padLeft(2, '0');
     final fileName = 'ccp3_cooling_$dateStr.pdf'; // e.g. ccp3_cooling_2026-02-19.pdf
     final storagePath = '$venueId/$year/$month/$fileName';
     
     // Upload
     final uploadedPath = await repo.uploadReport(storagePath, bytes);
     
     if (uploadedPath != null) {
        // Save Metadata
        await repo.saveReportMetadata(
           venueId: venueId,
           reportType: 'ccp3_cooling',
           generationDate: date,
           storagePath: uploadedPath,
           userId: user.id,
           metadata: {'generated_automatically': true},
        );
     }
  }

  return bytes;
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
            return const Center(
              child: Text(
                'Brak raportów dla wybranego dnia',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }
          return SfPdfViewer.memory(bytes);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Błąd generowania raportu: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
