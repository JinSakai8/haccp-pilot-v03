import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/core/services/drive_service.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/shared/config/form_definitions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_provider.g.dart';

@riverpod
ReportsRepository reportsRepository(Ref ref) => ReportsRepository();

@riverpod
PdfService pdfService(Ref ref) => PdfService();

@riverpod
DriveService driveService(Ref ref) => DriveService();

/// Holds generated report data as bytes + filename (web-compatible, no dart:io).
class ReportData {
  final Uint8List bytes;
  final String fileName;
  ReportData({required this.bytes, required this.fileName});
}

@riverpod
class ReportsNotifier extends _$ReportsNotifier {
  @override
  FutureOr<ReportData?> build() {
    return null;
  }

  /// Generates report and stores bytes in state (no filesystem writes on web).
  Future<void> generateReport({
    required String reportType,
    required DateTime month,
  }) async {
    state = const AsyncLoading();
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final repo = ref.read(reportsRepositoryProvider);
      final pdf = ref.read(pdfServiceProvider);
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
        pdfBytes = await pdf.generateTableReport(
          title: 'Karta Ewidencji Odpadów',
          columns: columns,
          rows: rows,
          userName: user?.fullName ?? 'System',
          dateRange: '${month.year}-${month.month.toString().padLeft(2, '0')}',
        );
      } else if (reportType == 'gmp_roasting') {
        final records = await repo.getGmpLogs(start, end);
        if (records.isEmpty) {
           throw Exception('Brak logów pieczenia w tym miesiącu');
        }

        final definition = FormDefinitions.getDefinition(reportType);
        final columns = ['Data', ...definition.fields.map((e) => e.label)];
        
        final rows = records.map((r) {
           final row = <String>[];
           row.add((r['created_at'] as String).substring(0, 16));
           final data = r['data'] as Map<String, dynamic>;
           for (var field in definition.fields) {
             row.add(data[field.id]?.toString() ?? '-');
           }
           return row;
        }).toList();

        fileName = 'Rejestr_Pieczenia_${month.year}_${month.month}.pdf';
        pdfBytes = await pdf.generateTableReport(
          title: 'Rejestr Procesu: Pieczenie',
          columns: columns,
          rows: rows,
          userName: user?.fullName ?? 'System',
          dateRange: '${month.year}-${month.month.toString().padLeft(2, '0')}',
        );
        
      } else {
        throw UnimplementedError('Raport $reportType nie jest jeszcze zaimplementowany');
      }

      state = AsyncData(ReportData(
        bytes: Uint8List.fromList(pdfBytes),
        fileName: fileName,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> uploadCurrentReport() async {
    final data = state.value;
    if (data == null) return;

    state = const AsyncLoading();
    try {
      final drive = ref.read(driveServiceProvider);
      await drive.uploadReportBytes(data.bytes, data.fileName);
      state = AsyncData(data); 
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
