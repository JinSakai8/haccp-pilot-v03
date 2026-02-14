import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/core/services/drive_service.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/shared/config/form_definitions.dart'; // Import Definitions
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_provider.g.dart';

@riverpod
ReportsRepository reportsRepository(Ref ref) => ReportsRepository();

@riverpod
PdfService pdfService(Ref ref) => PdfService();

@riverpod
DriveService driveService(Ref ref) => DriveService();

@riverpod
class ReportsNotifier extends _$ReportsNotifier {
  @override
  FutureOr<File?> build() {
    return null;
  }

  /// Generates report and returns the file.
  /// Also updates state with the file for UI to access.
  Future<void> generateReport({
    required String reportType, // 'waste', 'gmp', 'ghp', 'temperature'
    required DateTime month,
  }) async {
    state = const AsyncLoading();
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final repo = ref.read(reportsRepositoryProvider);
      final pdfService = ref.read(pdfServiceProvider);
      final user = ref.read(currentUserProvider);
      
      List<int> pdfBytes;
      String fileName;

      if (reportType == 'waste') {
        final records = await repo.getWasteRecords(start, end);
        if (records.isEmpty) {
          throw Exception('Brak danych o odpadach w tym miesiącu');
        }
        final columns = ['Data', 'Rodzaj', 'Kod', 'Masa (kg)', 'Odbiorca', 'KPO'];
        final rows = records.map((r) => [
          (r['created_at'] as String).substring(0, 10),
          r['waste_type'].toString(),
          r['waste_code'].toString(),
          r['mass_kg'].toString(),
          r['recipient_company'].toString(),
          r['kpo_number']?.toString() ?? '-',
        ]).toList();
        
        fileName = 'Karta_Odpadow_${month.year}_${month.month}.pdf';
        pdfBytes = await pdfService.generateTableReport(
          title: 'Karta Ewidencji Odpadów',
          columns: columns,
          rows: rows,
          userName: user?.fullName ?? 'System',
          dateRange: '${month.year}-${month.month.toString().padLeft(2, '0')}',
        );
      } else if (reportType == 'gmp_roasting') {
        // Fetch GMP logs
        final records = await repo.getGmpLogs(start, end);
        if (records.isEmpty) {
           throw Exception('Brak logów pieczenia w tym miesiącu');
        }

        // For GMP, we might generate ONE large PDF with multiple pages (one per log)
        // OR a Table Report if it fits. 
        // The user asked about "Dynamic Rows based on what cook saw".
        // This suggests using generateFormReport which is per-entry.
        // But generating 30 PDFs for a month is annoying. Usually it is a table summary.
        // HOWEVER, user asked "Czy PdfService wykorzystuje FormDefinition... raport musi dynamicznie tworzyć wiersze".
        // This implies the PDF structure reflects the FormDefinition.
        
        // Let's implement generating the LAST entry or a specific entry for now as a "Single Report",
        // OR a Combined Report where we iterate and draw tables.
        // For simplicity and matching the "FormDefinition" requirement, let's assume we want to print
        // a "Daily Report" or similar using the Definition.
        
        // If the user wants a MONTHLY report, it should be a table.
        // If the user wants a "Protocol" (single event), it uses FormDefinition.
        
        // Let's assume we are generating a Table Report based on Definition Labels for columns.
        
        final definition = FormDefinitions.getDefinition(reportType);
        final columns = ['Data', ...definition.fields.map((e) => e.label)];
        
        final rows = records.map((r) {
           final row = <String>[];
           row.add((r['created_at'] as String).substring(0, 16));
           
           // Parse JSONb 'data' column
           final data = r['data'] as Map<String, dynamic>;
           
           for (var field in definition.fields) {
             row.add(data[field.id]?.toString() ?? '-');
           }
           return row;
        }).toList();

        fileName = 'Rejestr_Pieczenia_${month.year}_${month.month}.pdf';
        pdfBytes = await pdfService.generateTableReport(
          title: 'Rejestr Procesu: Pieczenie',
          columns: columns,
          rows: rows,
          userName: user?.fullName ?? 'System',
          dateRange: '${month.year}-${month.month.toString().padLeft(2, '0')}',
        );
        
      } else {
        throw UnimplementedError('Raport $reportType nie jest jeszcze zaimplementowany');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      state = AsyncData(file);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> uploadCurrentReport() async {
    final file = state.value;
    if (file == null) return;

    state = const AsyncLoading();
    try {
      final driveService = ref.read(driveServiceProvider);
      await driveService.uploadReport(file, file.path.split('/').last);
      // Keep the file in state, maybe show success message via side-channel or another provider
      state = AsyncData(file); 
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

