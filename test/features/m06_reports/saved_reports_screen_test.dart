import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/m06_reports/providers/reports_provider.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';
import 'package:haccp_pilot/features/m06_reports/screens/saved_reports_screen.dart';

class _FakeReportsRepository extends ReportsRepository {
  Uint8List bytes = Uint8List.fromList('%PDF-1.4 fake'.codeUnits);

  @override
  Future<Uint8List?> downloadReport(String path) async => bytes;
}

class _FakePdfService extends PdfService {
  _FakePdfService() : super(useIsolate: false);

  int openCalls = 0;
  String? lastFileName;

  @override
  void openFile(Uint8List bytes, String fileName) {
    openCalls += 1;
    lastFileName = fileName;
  }
}

void main() {
  testWidgets('Saved reports exposes preview/download actions and opens PDF', (
    WidgetTester tester,
  ) async {
    final fakeRepo = _FakeReportsRepository();
    final fakePdf = _FakePdfService();

    final reports = <Map<String, dynamic>>[
      <String, dynamic>{
        'report_type': 'ghp_checklist_monthly',
        'generation_date': '2026-02-01',
        'created_at': '2026-02-27T09:00:00Z',
        'storage_path': 'reports/venue-1/2026/02/ghp_checklist_2026-02.pdf',
        'metadata': <String, dynamic>{'month': '2026-02'},
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsRepositoryProvider.overrideWithValue(fakeRepo),
          pdfServiceProvider.overrideWithValue(fakePdf),
          savedReportsProvider.overrideWith((ref) async => reports),
        ],
        child: const MaterialApp(home: SavedReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PODGLAD'), findsOneWidget);
    expect(find.text('POBIERZ'), findsOneWidget);

    await tester.tap(find.text('PODGLAD'));
    await tester.pumpAndSettle();

    expect(fakePdf.openCalls, equals(1));
    expect(fakePdf.lastFileName, equals('ghp_checklist_2026-02.pdf'));
  });
}
