import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/alarm_list_item.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';

void main() {
  test('TemperatureLog.fromJson converts timestamps to local time', () {
    final log = TemperatureLog.fromJson({
      'id': 'log-1',
      'sensor_id': 'sensor-1',
      'temperature_celsius': 5.6,
      'recorded_at': '2026-03-07T14:20:00.000Z',
      'is_alert': false,
      'is_acknowledged': false,
      'acknowledged_at': '2026-03-07T14:30:00.000Z',
      'edited_at': '2026-03-07T14:40:00.000Z',
    });

    expect(log.recordedAt, DateTime.parse('2026-03-07T14:20:00.000Z').toLocal());
    expect(log.acknowledgedAt, DateTime.parse('2026-03-07T14:30:00.000Z').toLocal());
    expect(log.editedAt, DateTime.parse('2026-03-07T14:40:00.000Z').toLocal());
  });

  test('AlarmListItem.fromJson converts timestamps to local time', () {
    final alarm = AlarmListItem.fromJson({
      'log_id': 'log-1',
      'sensor_id': 'sensor-1',
      'sensor_name': 'Chlodnia',
      'temperature': 12.3,
      'started_at': '2026-03-07T14:20:00.000Z',
      'last_seen_at': '2026-03-07T14:30:00.000Z',
      'duration_minutes': 10,
      'is_acknowledged': true,
      'acknowledged_at': '2026-03-07T14:35:00.000Z',
      'acknowledged_by': 'emp-1',
    });

    expect(alarm.startedAt, DateTime.parse('2026-03-07T14:20:00.000Z').toLocal());
    expect(alarm.lastSeenAt, DateTime.parse('2026-03-07T14:30:00.000Z').toLocal());
    expect(alarm.acknowledgedAt, DateTime.parse('2026-03-07T14:35:00.000Z').toLocal());
  });
}
