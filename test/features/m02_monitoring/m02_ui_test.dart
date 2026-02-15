import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m02_monitoring/screens/temperature_dashboard_screen.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/sensor.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m01_auth/models/employee.dart';
import 'package:haccp_pilot/core/models/venue.dart'; // Assuming Zone is here or defined elsewhere

// Mock overrides
final mockZone = Zone(id: 'zone-1', name: 'Kuchnia', type: 'kitchen');

final mockSensors = [
  Sensor(id: 's1', name: 'Chłodnia Mięs', zoneId: 'zone-1', isActive: true, intervalMinutes: 15),
  Sensor(id: 's2', name: 'Mroźnia', zoneId: 'zone-1', isActive: true, intervalMinutes: 60),
];

final mockLogs = [
  TemperatureLog(id: 'l1', sensorId: 's1', temperature: 3.5, recordedAt: DateTime.now(), isAlert: false, isAcknowledged: false),
];

void main() {
  testWidgets('TemperatureDashboardScreen displays sensors correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentZoneProvider.overrideWith((ref) => mockZone),
          activeSensorsProvider('zone-1').overrideWith((ref) async => mockSensors),
          // We override the stream provider to return our mock logs immediately
          latestMeasurementsProvider('zone-1').overrideWith((ref) => Stream.value(mockLogs)),
        ],
        child: const MaterialApp(
          home: TemperatureDashboardScreen(),
        ),
      ),
    );

    // Verify loading state or initial frame
    await tester.pump(); 
    // Wait for stream to emit
    await tester.pump(const Duration(milliseconds: 100));

    // Checks
    expect(find.text('Monitoring Temperatur'), findsOneWidget);
    expect(find.text('Chłodnia Mięs'), findsOneWidget);
    expect(find.text('3.5°C'), findsOneWidget);
    expect(find.text('Mroźnia'), findsOneWidget);
    expect(find.text('--.-°C'), findsOneWidget); // No log for s2
  });
}
