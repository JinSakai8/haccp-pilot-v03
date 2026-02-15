import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m06_reports/models/daily_temperature_stats.dart';
import 'package:haccp_pilot/features/m06_reports/services/temperature_aggregator_service.dart';

void main() {
  group('TemperatureAggregatorService', () {
    test('aggregates simple logs correctly', () {
      final now = DateTime(2026, 2, 15);
      final logs = [
        TemperatureLog(id: '1', sensorId: 's1', temperature: 2.0, recordedAt: now.add(const Duration(hours: 8)), isAlert: false),
        TemperatureLog(id: '2', sensorId: 's1', temperature: 4.0, recordedAt: now.add(const Duration(hours: 12)), isAlert: false),
        TemperatureLog(id: '3', sensorId: 's1', temperature: 6.0, recordedAt: now.add(const Duration(hours: 16)), isAlert: false),
      ];

      final result = TemperatureAggregatorService.aggregate(logs, deviceNames: {'s1': 'Fridge A'});

      expect(result.length, 1);
      final stat = result.first;
      expect(stat.deviceName, 'Fridge A');
      expect(stat.minTemp, 2.0);
      expect(stat.maxTemp, 6.0);
      expect(stat.avgTemp, 4.0); // (2+4+6)/3 = 4
      expect(stat.measurementCount, 3);
      expect(stat.hasCriticalBreach, false);
      expect(stat.date, DateTime(2026, 2, 15));
    });

    test('detects critical breaches', () {
      final now = DateTime(2026, 2, 15);
      final logs = [
        TemperatureLog(id: '1', sensorId: 's1', temperature: 5.0, recordedAt: now, isAlert: true),
      ];

      final result = TemperatureAggregatorService.aggregate(logs);

      expect(result.first.hasCriticalBreach, true);
    });

    test('groups multiple devices and days', () {
      final day1 = DateTime(2026, 2, 15);
      final day2 = DateTime(2026, 2, 16);
      
      final logs = [
        // Device 1 - Day 1
        TemperatureLog(id: '1', sensorId: 'd1', temperature: 2.0, recordedAt: day1, isAlert: false),
        // Device 1 - Day 2
        TemperatureLog(id: '2', sensorId: 'd1', temperature: 3.0, recordedAt: day2, isAlert: false),
        // Device 2 - Day 1
        TemperatureLog(id: '3', sensorId: 'd2', temperature: 5.0, recordedAt: day1, isAlert: false),
      ];

      final result = TemperatureAggregatorService.aggregate(logs, deviceNames: {'d1': 'D1', 'd2': 'D2'});

      expect(result.length, 3);
      
      // Expected order: Day 1 (D1, D2), Day 2 (D1)
      expect(result[0].date, day1);
      expect(result[0].deviceName, 'D1');
      
      expect(result[1].date, day1);
      expect(result[1].deviceName, 'D2');
      
      expect(result[2].date, day2);
      expect(result[2].deviceName, 'D1');
    });

    test('correctly maps missing device names', () {
      final logs = [
        TemperatureLog(id: '1', sensorId: 'unknown_id', temperature: 0.0, recordedAt: DateTime.now(), isAlert: false),
      ];

      final result = TemperatureAggregatorService.aggregate(logs);
      expect(result.first.deviceName, 'Sensor unknown_id');
    });
  });
}
