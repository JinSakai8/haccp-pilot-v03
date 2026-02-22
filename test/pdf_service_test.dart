import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
import 'package:haccp_pilot/features/shared/models/form_definition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

    test('generateCcp1TemperatureReport returns valid PDF bytes', () async {
      final rows = <List<String>>[
        ['01.02.2026', '08:00', '2.0\u00B0C', 'TAK', '', ''],
        ['01.02.2026', '08:15', '4.1\u00B0C', 'NIE', '', ''],
      ];

      final bytes = await pdfService.generateCcp1TemperatureReport(
        sensorName: 'Chlodnia Mies',
        userName: 'Tester',
        monthLabel: '2026-02',
        rows: rows,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');

      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();

      expect(text, contains('Arkusz monitorowania'));
      expect(text, contains('CCP-1'));
      expect(text, contains('Chlodnia Mies'));
      expect(text, contains('NIE'));
      expect(text, contains('Sprawdzil/zatwierdzil'));
    });

    test('generateCcp1TemperatureReport handles multipage dataset', () async {
      final rows = List<List<String>>.generate(320, (i) {
        final day = ((i % 28) + 1).toString().padLeft(2, '0');
        final minute = ((i * 5) % 60).toString().padLeft(2, '0');
        final temp = (i % 2 == 0) ? '3.0\u00B0C' : '4.5\u00B0C';
        final compliance = (i % 2 == 0) ? 'TAK' : 'NIE';
        return ['$day.02.2026', '08:$minute', temp, compliance, '', ''];
      });

      final bytes = await pdfService.generateCcp1TemperatureReport(
        sensorName: 'Sensor Multi',
        userName: 'Tester',
        monthLabel: '2026-02',
        rows: rows,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');

      final doc = PdfDocument(inputBytes: bytes);
      final pageCount = doc.pages.count;
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();

      expect(pageCount, greaterThan(1));
      expect(text, contains('Data'));
      expect(text, contains('Zgodnosc z'));
      expect(text, contains('ustaleniami'));
      expect(text, contains('Sprawdzil/zatwierdzil'));
    });
  });
}
