import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m06_reports/screens/ccp2_preview_screen.dart';

void main() {
  group('CCP2 row mapping', () {
    test('uses explicit is_compliant and corrective_actions', () {
      final row = mapHaccpLogToCcp2ReportRow({
        'created_at': '2026-02-14T10:15:00Z',
        'data': {
          'product_name': 'Kurczak',
          'internal_temp': 82,
          'is_compliant': false,
          'corrective_actions': 'Dopieczenie',
        },
      });

      expect(row.productName, equals('Kurczak'));
      expect(row.temperature, equals('82'));
      expect(row.isCompliant, isFalse);
      expect(row.correctiveActions, equals('Dopieczenie'));
    });

    test(
      'falls back to temperature threshold when compliance flag is missing',
      () {
        final below = mapHaccpLogToCcp2ReportRow({
          'created_at': '2026-02-14T10:15:00Z',
          'data': {'temperature': '89.9'},
        });
        final above = mapHaccpLogToCcp2ReportRow({
          'created_at': '2026-02-14T10:15:00Z',
          'data': {'temperature': '90.0'},
        });

        expect(below.isCompliant, isFalse);
        expect(above.isCompliant, isTrue);
      },
    );
  });
}
