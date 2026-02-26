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
        equals(DateTime(2026, 2, 23).subtract(const Duration(milliseconds: 1))),
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

    test(
      'does not apply tenant filter when both zone and venue are missing',
      () {
        final spec = buildCoolingLogsQuerySpec(
          DateTime(2026, 2, 22),
          zoneId: null,
          venueId: '',
        );

        expect(spec.usesZoneFilter, isFalse);
        expect(spec.usesVenueFallback, isFalse);
        expect(spec.zoneId, isNull);
        expect(spec.venueId, isNull);
      },
    );
  });

  group('RoastingLogsQuerySpec', () {
    test('contains fixed GMP roasting filters and month range', () {
      final spec = buildRoastingLogsQuerySpec(DateTime(2026, 2, 22, 15, 40));

      expect(spec.category, equals('gmp'));
      expect(spec.formId, equals('meat_roasting'));
      expect(spec.start, equals(DateTime(2026, 2, 1)));
      expect(
        spec.end,
        equals(DateTime(2026, 3, 1).subtract(const Duration(milliseconds: 1))),
      );
    });

    test('prioritizes zone filter over venue fallback', () {
      final spec = buildRoastingLogsQuerySpec(
        DateTime(2026, 2, 22),
        zoneId: 'zone-1',
        venueId: 'venue-1',
      );

      expect(spec.usesZoneFilter, isTrue);
      expect(spec.usesVenueFallback, isFalse);
      expect(spec.zoneId, equals('zone-1'));
      expect(spec.venueId, equals('venue-1'));
    });
  });

  group('Ccp1TemperatureQuerySpec', () {
    test('builds full month range and keeps single sensor', () {
      final spec = buildCcp1TemperatureQuerySpec(
        DateTime(2026, 2, 22, 15, 40),
        'sensor-1',
      );

      expect(spec.sensorId, equals('sensor-1'));
      expect(spec.start, equals(DateTime(2026, 2, 1, 0, 0, 0)));
      expect(
        spec.end,
        equals(DateTime(2026, 3, 1).subtract(const Duration(milliseconds: 1))),
      );
    });

    test('normalizes sensor id by trimming whitespace', () {
      final spec = buildCcp1TemperatureQuerySpec(
        DateTime(2026, 2, 1),
        '  sensor-1  ',
      );

      expect(spec.sensorId, equals('sensor-1'));
    });
  });

  group('CCP1 row mapping', () {
    test('maps fixed output columns and compliance boundaries', () {
      final samples = <Map<String, dynamic>>[
        {
          'sensor_id': 's1',
          'temperature_celsius': -0.1,
          'recorded_at': '2026-02-22T08:15:00Z',
        },
        {
          'sensor_id': 's1',
          'temperature_celsius': 0.0,
          'recorded_at': '2026-02-22T08:16:00Z',
        },
        {
          'sensor_id': 's1',
          'temperature_celsius': 4.0,
          'recorded_at': '2026-02-22T08:17:00Z',
        },
        {
          'sensor_id': 's1',
          'temperature_celsius': 4.1,
          'recorded_at': '2026-02-22T08:18:00Z',
        },
      ];

      final rows = samples.map(mapTemperatureLogToCcp1Row).toList();

      expect(rows[0].compliance, equals('NIE'));
      expect(rows[1].compliance, equals('TAK'));
      expect(rows[2].compliance, equals('TAK'));
      expect(rows[3].compliance, equals('NIE'));

      expect(rows[1].date, equals('22.02.2026'));
      expect(rows[1].time, equals('08:16'));
      expect(rows[1].temperature, equals('0.0\u00B0C'));
      expect(rows[1].correctiveActions, isEmpty);
      expect(rows[1].signature, isEmpty);
    });
  });
}
