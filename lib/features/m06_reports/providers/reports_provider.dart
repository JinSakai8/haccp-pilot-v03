import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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
  final String? archiveWarning;
  ReportData({
    required this.bytes,
    required this.fileName,
    this.archiveWarning,
  });
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
    String? sensorId,
  }) async {
    debugPrint(
      'M06: Generating report: $reportType, Month: $month, Sensor: $sensorId',
    );
    state = const AsyncLoading();
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final repo = ref.read(reportsRepositoryProvider);
      final pdf = ref.read(pdfServiceProvider);
      final user = ref.read(currentUserProvider);

      List<int> pdfBytes;
      String fileName;
      String? archiveWarning;

      if (reportType == 'waste') {
        final records = await repo.getWasteRecords(start, end);
        if (records.isEmpty) {
          throw Exception('Brak danych o odpadach w tym miesiacu');
        }
        final columns = [
          'Data',
          'Rodzaj',
          'Kod',
          'Masa (kg)',
          'Odbiorca',
          'KPO',
        ];
        final rows = records
            .map(
              (r) => [
                (r['created_at'] as String).substring(0, 10),
                r['waste_type'].toString(),
                r['waste_code'].toString(),
                r['mass_kg'].toString(),
                r['recipient_company'].toString(),
                r['kpo_number']?.toString() ?? '-',
              ],
            )
            .toList();

        fileName = 'Karta_Odpadow_${month.year}_${month.month}.pdf';
        pdfBytes = await pdf.generateTableReport(
          title: 'Karta Ewidencji Odpadow',
          columns: columns,
          rows: rows,
          userName: user?.fullName ?? 'System',
          dateRange: '${month.year}-${month.month.toString().padLeft(2, '0')}',
        );
      } else if (reportType == 'gmp_roasting' || reportType == 'gmp') {
        final records = await repo.getGmpLogs(start, end);
        if (records.isEmpty) {
          throw Exception('Brak logow HACCP w tym miesiacu');
        }

        final typeKey = reportType == 'gmp' ? 'gmp_roasting' : reportType;
        final definition = FormDefinitions.getDefinition(typeKey);
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

        fileName = 'Rejestr_HACCP_${month.year}_${month.month}.pdf';
        pdfBytes = await pdf.generateTableReport(
          title: 'Rejestr Procesu: ${definition.title}',
          columns: columns,
          rows: rows,
          userName: user?.fullName ?? 'System',
          dateRange: '${month.year}-${month.month.toString().padLeft(2, '0')}',
        );
      } else if (reportType == 'ghp') {
        throw Exception(
          'Raport GHP jest w trakcie przygotowania. Uzyj GMP lub Temperatur.',
        );
      } else if (reportType == 'temperature') {
        if (sensorId == null || sensorId.trim().isEmpty) {
          throw Exception('Wybierz urzadzenie dla raportu CCP-1 temperatur.');
        }

        final periodStart = DateTime(month.year, month.month, 1);
        final periodEnd = DateTime(
          month.year,
          month.month + 1,
          1,
        ).subtract(const Duration(milliseconds: 1));

        final dataset = await repo.getCcp1TemperatureDataset(
          month: month,
          sensorId: sensorId,
        );

        if (dataset.rows.isEmpty) {
          throw Exception(
            'Brak pomiarow temperatur dla wybranego urzadzenia w tym miesiacu',
          );
        }

        final rows = dataset.rows.map((row) => row.toPdfColumns()).toList();
        final monthStr =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';

        pdfBytes = await pdf.generateCcp1TemperatureReport(
          sensorName: dataset.sensorName,
          userName: user?.fullName ?? 'System',
          monthLabel: monthStr,
          rows: rows,
        );
        fileName = 'ccp1_temperature_${dataset.sensorId}_$monthStr.pdf';

        final venueId = await _resolveVenueId();
        if (venueId == null || venueId.isEmpty) {
          archiveWarning =
              'Raport wygenerowano, ale brak venue_id do archiwizacji CCP-1.';
        } else if (user == null) {
          archiveWarning =
              'Raport wygenerowano, ale brak zalogowanego uzytkownika do archiwizacji CCP-1.';
        } else {
          try {
            final storagePathInBucket =
                '$venueId/${month.year}/${month.month.toString().padLeft(2, '0')}/$fileName';
            final uploadedPath = await repo.uploadReport(
              storagePathInBucket,
              Uint8List.fromList(pdfBytes),
            );
            if (uploadedPath == null) {
              archiveWarning =
                  'Raport wygenerowano, ale nie udalo sie zapisac pliku CCP-1 w storage.';
            } else {
              await repo.saveReportMetadata(
                venueId: venueId,
                reportType: 'ccp1_temperature',
                generationDate: periodStart,
                storagePath: 'reports/$uploadedPath',
                userId: user.id,
                periodStart: periodStart,
                periodEnd: periodEnd,
                metadata: {
                  'sensor_id': dataset.sensorId,
                  'sensor_name': dataset.sensorName,
                  'month': monthStr,
                  'template_version': 'ccp1_csv_v1',
                },
              );
            }
          } catch (_) {
            archiveWarning =
                'Raport wygenerowano, ale nie udalo sie zapisac metadanych archiwum CCP-1.';
          }
        }
      } else {
        throw UnimplementedError(
          'Raport $reportType nie jest jeszcze zaimplementowany',
        );
      }

      state = AsyncData(
        ReportData(
          bytes: Uint8List.fromList(pdfBytes),
          fileName: fileName,
          archiveWarning: archiveWarning,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> _resolveVenueId() async {
    final zone = ref.read(currentZoneProvider);
    if (zone != null && zone.venueId.isNotEmpty) {
      return zone.venueId;
    }

    final zones = await ref.read(employeeZonesProvider.future);
    if (zones.isNotEmpty && zones.first.venueId.isNotEmpty) {
      return zones.first.venueId;
    }
    return null;
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
