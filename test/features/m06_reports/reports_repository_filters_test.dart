import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';

void main() {
  group('CoolingLogsQuerySpec', () {
    test('contains fixed GMP cooling filters and day range', () {
      final spec = buildCoolingLogsQuerySpec(DateTime(2026, 2, 22, 15, 40));

      expect(spec.category, equals('gmp'));
      expect(spec.formId, equals('food_cooling'));
      expect(spec.start, equals(DateTime(2026, 2, 22)));
      expect(
        spec.end,
        equals(
          DateTime(2026, 2, 23).subtract(const Duration(milliseconds: 1)),
        ),
      );
    });

    test('prioritizes zone filter over venue fallback', () {
      final spec = buildCoolingLogsQuerySpec(
        DateTime(2026, 2, 22),
        zoneId: 'zone-1',
        venueId: 'venue-1',
      );

      expect(spec.usesZoneFilter, isTrue);
      expect(spec.usesVenueFallback, isFalse);
      expect(spec.zoneId, equals('zone-1'));
      expect(spec.venueId, equals('venue-1'));
    });

    test('uses venue fallback when zone is missing', () {
      final spec = buildCoolingLogsQuerySpec(
        DateTime(2026, 2, 22),
        zoneId: '  ',
        venueId: 'venue-1',
      );

      expect(spec.usesZoneFilter, isFalse);
      expect(spec.usesVenueFallback, isTrue);
      expect(spec.zoneId, isNull);
      expect(spec.venueId, equals('venue-1'));
    });

    test('does not apply tenant filter when both zone and venue are missing', () {
      final spec = buildCoolingLogsQuerySpec(
        DateTime(2026, 2, 22),
        zoneId: null,
        venueId: '',
      );

      expect(spec.usesZoneFilter, isFalse);
      expect(spec.usesVenueFallback, isFalse);
      expect(spec.zoneId, isNull);
      expect(spec.venueId, isNull);
    });
  });
}
