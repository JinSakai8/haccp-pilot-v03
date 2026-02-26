import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/models/employee.dart';
import 'package:haccp_pilot/core/models/zone.dart';
import 'package:haccp_pilot/core/services/drive_service.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';

class _FakeReportsRepository extends ReportsRepository {
  Ccp1TemperatureDataset dataset = Ccp1TemperatureDataset(
    sensorId: 'sensor-1',
    sensorName: 'Sensor 1',
    month: DateTime(2026, 2, 1),
    rows: const <Ccp1TemperatureReportRow>[
      Ccp1TemperatureReportRow(
        date: '01.02.2026',
        time: '08:00',
        temperature: '2.0\u00B0C',
        compliance: 'TAK',
        correctiveActions: '',
        signature: '',
      ),
    ],
  );

  String? uploadedPathResult =
      'venue-1/2026/02/ccp1_temperature_sensor-1_2026-02.pdf';
  bool throwOnSaveMetadata = false;

  String? lastUploadPath;
  Map<String, dynamic>? lastSavedMetadata;
  String? lastSavedReportType;
  String? lastSavedStoragePath;
  String? lastSavedVenueId;
  String? lastSavedUserId;

  @override
  Future<Ccp1TemperatureDataset> getCcp1TemperatureDataset({
    required DateTime month,
    required String sensorId,
  }) async {
    return dataset;
  }

  @override
  Future<String?> uploadReport(String path, Uint8List bytes) async {
    lastUploadPath = path;
    return uploadedPathResult;
  }

  @override
  Future<void> saveReportMetadata({
    required String venueId,
    required String reportType,
    required DateTime generationDate,
    required String storagePath,
    required String userId,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? templateVersion,
    String? sourceFormId,
    Map<String, dynamic>? metadata,
  }) async {
    if (throwOnSaveMetadata) {
      throw Exception('save metadata failed');
    }
    lastSavedVenueId = venueId;
    lastSavedReportType = reportType;
    lastSavedStoragePath = storagePath;
    lastSavedUserId = userId;
    lastSavedMetadata = metadata;
  }
}

class _FakePdfService extends PdfService {
  _FakePdfService() : super(useIsolate: false);

  @override
  Future<Uint8List> generateCcp1TemperatureReport({
    required String sensorName,
    required String userName,
    required String monthLabel,
    required List<List<String>> rows,
  }) async {
    return Uint8List.fromList('%PDF-fake-ccp1'.codeUnits);
  }
}

class _FakeDriveService extends DriveService {}

void main() {
  group('ReportsNotifier Sprint4 integration', () {
    late _FakeReportsRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = _FakeReportsRepository();
      container = ProviderContainer(
        overrides: [
          reportsRepositoryProvider.overrideWithValue(fakeRepo),
          pdfServiceProvider.overrideWithValue(_FakePdfService()),
          driveServiceProvider.overrideWithValue(_FakeDriveService()),
        ],
      );

      container
          .read(currentUserProvider.notifier)
          .set(
            Employee(
              id: 'user-1',
              fullName: 'Tester',
              role: 'manager',
              isActive: true,
            ),
          );
      container
          .read(currentZoneProvider.notifier)
          .set(Zone(id: 'zone-1', name: 'Kuchnia', venueId: 'venue-1'));
    });

    tearDown(() {
      container.dispose();
    });

    test('success: generates pdf and archives ccp1 metadata', () async {
      await container
          .read(reportsProvider.notifier)
          .generateReport(
            reportType: 'temperature',
            month: DateTime(2026, 2, 1),
            sensorId: 'sensor-1',
          );

      final state = container.read(reportsProvider);
      expect(state.hasValue, isTrue);
      expect(fakeRepo.lastUploadPath, isNotNull);
      expect(fakeRepo.lastSavedReportType, equals('ccp1_temperature'));
      expect(fakeRepo.lastSavedStoragePath, startsWith('reports/'));
      expect(fakeRepo.lastSavedVenueId, equals('venue-1'));
      expect(fakeRepo.lastSavedUserId, equals('user-1'));
      expect(fakeRepo.lastSavedMetadata?['sensor_id'], equals('sensor-1'));
      expect(fakeRepo.lastSavedMetadata?['sensor_name'], equals('Sensor 1'));
      expect(fakeRepo.lastSavedMetadata?['month'], equals('2026-02'));
      expect(
        fakeRepo.lastSavedMetadata?['template_version'],
        equals('ccp1_csv_v1'),
      );
    });

    test('missing sensor: returns error', () async {
      await container
          .read(reportsProvider.notifier)
          .generateReport(
            reportType: 'temperature',
            month: DateTime(2026, 2, 1),
            sensorId: null,
          );

      final state = container.read(reportsProvider);
      expect(state.hasError, isTrue);
    });

    test('no data: returns error', () async {
      fakeRepo.dataset = Ccp1TemperatureDataset(
        sensorId: 'sensor-1',
        sensorName: 'Sensor 1',
        month: DateTime(2026, 2, 1),
        rows: const <Ccp1TemperatureReportRow>[],
      );

      await container
          .read(reportsProvider.notifier)
          .generateReport(
            reportType: 'temperature',
            month: DateTime(2026, 2, 1),
            sensorId: 'sensor-1',
          );

      final state = container.read(reportsProvider);
      expect(state.hasError, isTrue);
    });

    test('upload error: returns error', () async {
      fakeRepo.uploadedPathResult = null;

      await container
          .read(reportsProvider.notifier)
          .generateReport(
            reportType: 'temperature',
            month: DateTime(2026, 2, 1),
            sensorId: 'sensor-1',
          );

      final state = container.read(reportsProvider);
      expect(state.hasError, isTrue);
    });

    test('metadata save error: returns error', () async {
      fakeRepo.throwOnSaveMetadata = true;

      await container
          .read(reportsProvider.notifier)
          .generateReport(
            reportType: 'temperature',
            month: DateTime(2026, 2, 1),
            sensorId: 'sensor-1',
          );

      final state = container.read(reportsProvider);
      expect(state.hasError, isTrue);
    });
  });
}
