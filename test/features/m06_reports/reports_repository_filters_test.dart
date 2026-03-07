import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m06_reports/repositories/reports_repository.dart';
import 'package:haccp_pilot/features/m06_reports/screens/saved_reports_screen.dart';

void main() {
  group('CoolingLogsQuerySpec', () {
    test('contains fixed GMP cooling filters and month range', () {
      final spec = buildCoolingLogsQuerySpec(DateTime(2026, 2, 22, 15, 40));

      expect(spec.category, equals('gmp'));
      expect(spec.formId, equals('food_cooling'));
      expect(spec.start, equals(DateTime(2026, 2, 1)));
      expect(
        spec.end,
        equals(DateTime(2026, 3, 1).subtract(const Duration(milliseconds: 1))),
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
      expect(
        spec.formIds,
        equals(<String>['meat_roasting', 'meat_roasting_daily']),
      );
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

    test('business date prefers prep_date over created_at', () {
      final resolved = resolveRoastingLogBusinessDate({
        'created_at': '2026-03-01T08:00:00Z',
        'data': {'prep_date': '2026-02-28'},
      });

      expect(resolved, equals(DateTime(2026, 2, 28)));
    });

    test('business date falls back to created_at for legacy rows', () {
      final resolved = resolveRoastingLogBusinessDate({
        'created_at': '2026-02-15T08:00:00Z',
        'data': <String, dynamic>{},
      });

      expect(resolved, equals(DateTime.parse('2026-02-15T08:00:00Z')));
    });

    test('month filter uses business date contract', () {
      final inMonthByPrepDate = isRoastingLogInMonth({
        'created_at': '2026-03-01T08:00:00Z',
        'data': {'prep_date': '2026-02-28'},
      }, DateTime(2026, 2, 1));

      final outMonthByPrepDate = isRoastingLogInMonth({
        'created_at': '2026-02-20T08:00:00Z',
        'data': {'prep_date': '2026-03-01'},
      }, DateTime(2026, 2, 1));

      final legacyInMonth = isRoastingLogInMonth({
        'created_at': '2026-02-20T08:00:00Z',
        'data': <String, dynamic>{},
      }, DateTime(2026, 2, 1));

      expect(inMonthByPrepDate, isTrue);
      expect(outMonthByPrepDate, isFalse);
      expect(legacyInMonth, isTrue);
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

  group('GHP row mapping', () {
    test('maps execution metadata and answer summary for PDF rows', () {
      final row = mapGhpLogToReportRow({
        'form_id': 'ghp_personnel',
        'created_at': '2026-02-27T12:30:00Z',
        'data': {
          'execution_date': '2026-02-27',
          'execution_time': '12:15',
          'answers': {'uniform': true, 'hands': false, 'health': true},
          'notes': 'Brak uwag',
        },
      });

      expect(row.length, equals(6));
      expect(row[0], equals('2026-02-27'));
      expect(row[1], equals('12:15'));
      expect(row[2], equals('ghp_personnel'));
      expect(row[3], contains('Pytania: 3'));
      expect(row[3], contains('TAK: 2'));
      expect(row[3], contains('NIE: 1'));
      expect(row[4], equals('Brak uwag'));
      expect(row[5], equals('2026-02-27T12:30'));
    });

    test('supports legacy ghp form id and snapshot answers map', () {
      final row = mapGhpLogToReportRow({
        'form_id': 'rooms',
        'created_at': '2026-02-28T09:10:00Z',
        'data': {
          'execution_date': '2026-02-28',
          'execution_time': '08:55',
          'answers': {
            'selected_room': {'id': 'room-1', 'name': 'kuchnia'},
            'floors': true,
            'tables': false,
          },
        },
      });

      expect(row.length, equals(6));
      expect(row[0], equals('2026-02-28'));
      expect(row[1], equals('08:55'));
      expect(row[2], equals('rooms'));
      expect(row[3], contains('Pytania: 3'));
      expect(row[3], contains('TAK: 1'));
      expect(row[3], contains('NIE: 1'));
      expect(row[5], equals('2026-02-28T09:10'));
    });
  });

  group('Saved reports fallback route', () {
    test('returns force preview route for ccp2/ccp3 and null for others', () {
      expect(
        buildFallbackPreviewRoute('ccp2_roasting', '2026-02-01'),
        equals('/reports/preview/ccp2?date=2026-02-01&force=1'),
      );
      expect(
        buildFallbackPreviewRoute('ccp3_cooling', '2026-02-01'),
        equals('/reports/preview/ccp3?date=2026-02-01&force=1'),
      );
      expect(
        buildFallbackPreviewRoute('ghp_checklist_monthly', '2026-02-01'),
        isNull,
      );
      expect(buildFallbackPreviewRoute('ccp2_roasting', 'bad-date'), isNull);
    });
  });
}
