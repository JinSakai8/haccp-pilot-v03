import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/shared/config/form_definitions.dart';
import 'package:haccp_pilot/features/shared/models/form_definition.dart'; // Import Request

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Required for services/compute

  group('PdfService Tests', () {
    final pdfService = PdfService();

    test('generateTableReport returns bytes', () async {
      final bytes = await pdfService.generateTableReport(
        title: 'Test Report',
        columns: ['Col A', 'Col B'],
        rows: [
          ['Val 1', 'Val 2'],
          ['Val 3', 'Val 4'],
        ],
        userName: 'Tester',
        dateRange: '2026-02',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100)); // Basic PDF header size check
      // Can we check for pdf signature? bytes[0-4] should be %PDF
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('generateFormReport returns bytes for Roasting Form', () async {
      final definition = FormDefinitions.roastingFormDef;
      final data = {
        'product_name': 'Kurczak',
        'internal_temp': 85.0,
        'comments': true, // Toggle value
      };

      final bytes = await pdfService.generateFormReport(
        title: 'Test Form Report',
        definition: definition,
        data: data,
        userName: 'Tester',
        date: '2026-02-14 10:00',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
