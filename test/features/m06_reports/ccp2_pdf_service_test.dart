import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/services/pdf_service.dart';
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
            final bytes = File(
              'assets/fonts/Roboto-Regular.ttf',
            ).readAsBytesSync();
            return ByteData.view(Uint8List.fromList(bytes).buffer);
          }
          if (key == 'assets/fonts/Roboto-Bold.ttf') {
            final bytes = File(
              'assets/fonts/Roboto-Bold.ttf',
            ).readAsBytesSync();
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

  test('generateCcp2Report returns valid PDF bytes', () async {
    final service = PdfService(useIsolate: false);
    final bytes = await service.generateCcp2Report(
      rows: const [
        Ccp2ReportRow(
          dateTime: '01.02.2026\n08:15',
          productName: 'Kurczak',
          temperature: '92',
          isCompliant: true,
          correctiveActions: '',
        ),
      ],
      userName: 'Tester',
      monthLabel: '2026-02',
      venueName: 'Mieso i Piana',
      venueAddress: 'ul. Energetykow 18A',
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');

    final doc = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(doc).extractText();
    doc.dispose();

    expect(text, contains('CCP-2'));
    expect(text, contains('Kurczak'));
  });
}
