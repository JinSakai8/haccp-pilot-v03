import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:haccp_pilot/core/theme/app_theme.dart';
import 'package:haccp_pilot/core/widgets/haccp_top_bar.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';

// Simple provider to access ReportsRepository (assuming standard riverpod pattern or instance)
// If not available globally, we instantiate here for the screen.
final reportsRepositoryProvider = Provider((ref) => ReportsRepository());

final ccp3ReportProvider = FutureProvider.family<Uint8List?, DateTime>((ref, date) async {
  final repo = ref.read(reportsRepositoryProvider);
  final logs = await repo.getCoolingLogs(date);
  
  if (logs.isEmpty) return null; // Return null to signal empty state

  // Get User Name (Mock or from Auth)
  final user = ref.read(currentUserProvider);
  final userName = user?.fullName ?? 'Użytkownik';
  
  // Get Logo (Mock or fetch)
  // Uint8List? logo = await repo.getVenueLogo(venueId);
  
  final pdfService = PdfService();
  return await pdfService.generateCcp3Report(
    logs: logs,
    userName: userName,
    date: date.toIso8601String().split('T')[0], // YYYY-MM-DD
    venueLogo: null, // Add logo logic if needed
  );
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
                 final file = XFile.fromData(bytes, name: 'CCP3_Raport.pdf', mimeType: 'application/pdf');
                 await Share.shareXFiles([file], text: 'Raport CCP-3');
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
