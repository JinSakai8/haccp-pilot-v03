import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/models/zone.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/sensor.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/screens/temperature_dashboard_screen.dart';

final mockZone = Zone(id: 'zone-1', name: 'Kuchnia', venueId: 'venue-1');

class _TestCurrentZoneNotifier extends CurrentZoneNotifier {
  @override
  Zone? build() => mockZone;
}

final mockSensors = [
  Sensor(
    id: 's1',
    name: 'Sensor A',
    zoneId: 'zone-1',
    isActive: true,
    intervalMinutes: 15,
  ),
  Sensor(
    id: 's2',
    name: 'Sensor B',
    zoneId: 'zone-1',
    isActive: true,
    intervalMinutes: 60,
  ),
];

final mockLogs = [
  TemperatureLog(
    id: 'l1',
    sensorId: 's1',
    temperature: 3.5,
    recordedAt: DateTime.now(),
    isAlert: false,
  ),
];

void main() {
  testWidgets('TemperatureDashboardScreen displays sensors correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentZoneProvider.overrideWith(_TestCurrentZoneNotifier.new),
          activeSensorsProvider('zone-1')
              .overrideWith((ref) async => mockSensors),
          latestMeasurementsProvider('zone-1')
              .overrideWith((ref) => Stream.value(mockLogs)),
        ],
        child: const MaterialApp(
          home: TemperatureDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Monitoring Temperatur'), findsOneWidget);
    expect(find.text('Sensor A'), findsOneWidget);
    expect(find.textContaining('3.5'), findsOneWidget);
    expect(find.text('Sensor B'), findsOneWidget);
    expect(find.textContaining('--.-'), findsOneWidget);
  });
}
