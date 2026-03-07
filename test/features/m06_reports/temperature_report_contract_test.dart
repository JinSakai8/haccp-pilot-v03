import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M06 temperature report contract', () {
    test('provider uses CCP-1 dataset path and no HTML generator', () {
      final content = File(
        'lib/features/m06_reports/providers/reports_provider.dart',
      ).readAsStringSync();

      expect(content, contains("getCcp1TemperatureDataset("));
      expect(content, isNot(contains('HtmlReportGenerator')));
      expect(content, isNot(contains('.html')));
    });
  });
}

