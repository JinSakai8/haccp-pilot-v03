import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m06_reports/screens/ccp2_preview_screen.dart';

void main() {
  group('CCP2 row mapping', () {
    test('uses explicit is_compliant and corrective_actions', () {
      final row = mapHaccpLogToCcp2ReportRow({
        'created_at': '2026-02-14T10:15:00Z',
        'data': {
          'prep_date': '2026-02-14',
          'product_name': 'Kurczak',
          'temperature': 82,
          'is_compliant': false,
          'corrective_actions': 'Dopieczenie',
          'signature': 'AB',
        },
      });

      expect(row.productName, equals('Kurczak'));
      expect(row.temperature, equals('82'));
      expect(row.isCompliant, isFalse);
      expect(row.correctiveActions, equals('Dopieczenie'));
      expect(row.signature, equals('AB'));
      expect(row.dateTime, equals('14.02.2026'));
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

    test('supports legacy records with internal_temp and created_at only', () {
      final row = mapHaccpLogToCcp2ReportRow({
        'created_at': '2026-02-15T11:20:00Z',
        'data': {'internal_temp': 93, 'product_name': 'Schab'},
      });

      expect(row.temperature, equals('93'));
      expect(row.dateTime, equals('15.02.2026'));
      expect(row.productName, equals('Schab'));
    });
  });
}
