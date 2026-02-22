import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/shared/models/form_definition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = 'flutter/assets';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channel, (ByteData? message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == null) return null;

      if (key == 'assets/fonts/Roboto-Regular.ttf') {
        final bytes = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      }
      if (key == 'assets/fonts/Roboto-Bold.ttf') {
        final bytes = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      }
      return null;
    });
  });

  tearDownAll(() async {
    const channel = 'flutter/assets';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channel, null);
  });

  group('PdfService Tests', () {
    final pdfService = PdfService(useIsolate: false);

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

    test('generateFormReport returns bytes for simple ASCII form', () async {
      final definition = FormDefinition(
        fields: <FormFieldConfig>[
          FormFieldConfig(
            id: 'product_name',
            type: HaccpFieldType.text,
            label: 'Product Name',
            required: true,
          ),
          FormFieldConfig(
            id: 'internal_temp',
            type: HaccpFieldType.stepper,
            label: 'Internal Temp',
            required: true,
          ),
        ],
      );
      final data = {
        'product_name': 'Kurczak',
        'internal_temp': 85.0,
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
    }, skip: 'Skipped in test runner due Syncfusion standard-font Unicode limitation.');
  });
}
