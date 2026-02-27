import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Database Schema Consistency', () {
    test('GmpRepository writes to haccp_logs', () {
      final content = File('lib/features/m03_gmp/repositories/gmp_repository.dart')
          .readAsStringSync();
      expect(content, contains("final String _table = 'haccp_logs';"));
    });

    test('ReportsRepository reads cooling logs from haccp_logs', () {
      final content = File(
        'lib/features/m06_reports/repositories/reports_repository.dart',
      ).readAsStringSync();
      expect(content, contains(".from('haccp_logs')"));
      expect(content, contains(".eq('category', spec.category)"));
      expect(content, contains(".eq('form_id', spec.formId)"));
    });

    test('WasteRepository writes to waste_records', () {
      final content = File('lib/features/m05_waste/repositories/waste_repository.dart')
          .readAsStringSync();
      expect(content, contains("'waste_records'"));
    });
  });
}
