import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/models/employee.dart';
import 'package:haccp_pilot/core/models/zone.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/alarm_list_item.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/screens/alarms_panel_screen.dart';
import 'package:haccp_pilot/core/widgets/haccp_long_press_button.dart';

void main() {
  const zoneId = 'zone-1';

  AlarmListItem activeAlarm() {
    final now = DateTime.now();
    return AlarmListItem(
      logId: 'log-active',
      sensorId: 'sensor-1',
      sensorName: 'Chlodnia #1',
      temperature: 12.3,
      startedAt: now.subtract(const Duration(minutes: 45)),
      lastSeenAt: now,
      durationMinutes: 45,
      isAcknowledged: false,
    );
  }

  AlarmListItem historyAlarm() {
    final now = DateTime.now();
    return AlarmListItem(
      logId: 'log-history',
      sensorId: 'sensor-2',
      sensorName: 'Mroznia #2',
      temperature: 11.0,
      startedAt: now.subtract(const Duration(hours: 1)),
      lastSeenAt: now.subtract(const Duration(minutes: 5)),
      durationMinutes: 55,
      isAcknowledged: true,
      acknowledgedAt: now.subtract(const Duration(minutes: 5)),
      acknowledgedBy: 'employee-12345678',
    );
  }

  testWidgets('renders active alarm card with long press action', (tester) async {
    final container = ProviderContainer(
      overrides: [
        alarmsProvider(zoneId, activeOnly: true).overrideWith(
          (ref) async => [activeAlarm()],
        ),
        alarmsProvider(zoneId, activeOnly: false).overrideWith(
          (ref) async => [historyAlarm()],
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentZoneProvider.notifier).set(
          Zone(id: zoneId, name: 'Kuchnia', venueId: 'venue-1'),
        );
    container.read(currentUserProvider.notifier).set(
          Employee(
            id: 'emp-manager',
            fullName: 'Manager',
            role: 'manager',
            isActive: true,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AlarmsPanelScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alarmy'), findsOneWidget);
    expect(find.text('Chlodnia #1'), findsOneWidget);
    expect(find.textContaining('Od:'), findsOneWidget);
    expect(find.text('Przyjalem do wiadomosci'), findsOneWidget);

    final buttonFinder = find.byType(HaccpLongPressButton);
    final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Przyjalem do wiadomosci'), findsOneWidget);
  });

  testWidgets('renders history metadata and no ack button in history tab', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        alarmsProvider(zoneId, activeOnly: true).overrideWith(
          (ref) async => const [],
        ),
        alarmsProvider(zoneId, activeOnly: false).overrideWith(
          (ref) async => [historyAlarm()],
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentZoneProvider.notifier).set(
          Zone(id: zoneId, name: 'Kuchnia', venueId: 'venue-1'),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AlarmsPanelScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('HISTORIA'));
    await tester.pumpAndSettle();

    expect(find.text('Mroznia #2'), findsOneWidget);
    expect(find.textContaining('Potwierdzono'), findsAtLeastNWidgets(1));
    expect(find.text('Przyjalem do wiadomosci'), findsNothing);
  });

  testWidgets('does not overflow on 360px width', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        alarmsProvider(zoneId, activeOnly: true).overrideWith(
          (ref) async => [activeAlarm()],
        ),
        alarmsProvider(zoneId, activeOnly: false).overrideWith(
          (ref) async => const [],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentZoneProvider.notifier).set(
          Zone(id: zoneId, name: 'Kuchnia', venueId: 'venue-1'),
        );
    container.read(currentUserProvider.notifier).set(
          Employee(
            id: 'emp-manager',
            fullName: 'Manager',
            role: 'manager',
            isActive: true,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AlarmsPanelScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
