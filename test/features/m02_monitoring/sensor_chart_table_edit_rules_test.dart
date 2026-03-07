import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/models/employee.dart';
import 'package:haccp_pilot/core/providers/auth_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/models/temperature_log.dart';
import 'package:haccp_pilot/features/m02_monitoring/providers/monitoring_provider.dart';
import 'package:haccp_pilot/features/m02_monitoring/screens/sensor_chart_screen.dart';

void main() {
  const sensorId = 'sensor-1';

  testWidgets(
    'manager sees edit enabled for 6d23h and disabled for older than 7d',
    (tester) async {
      final now = DateTime.now();
      final logs = [
        TemperatureLog(
          id: 'recent',
          sensorId: sensorId,
          temperature: 4.2,
          recordedAt: now.subtract(
            const Duration(days: 6, hours: 23),
          ),
          isAlert: false,
        ),
        TemperatureLog(
          id: 'old',
          sensorId: sensorId,
          temperature: 5.1,
          recordedAt: now.subtract(
            const Duration(days: 7, minutes: 1),
          ),
          isAlert: false,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          sensorHistoryProvider(
            sensorId,
            const Duration(hours: 24),
          ).overrideWith((ref) async => const []),
          sensorSevenDayTableProvider(
            sensorId,
          ).overrideWith((ref) async => logs),
        ],
      );
      addTearDown(container.dispose);
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
          child: const MaterialApp(home: SensorChartScreen(deviceId: sensorId)),
        ),
      );

      await tester.tap(find.text('Tabela 7 dni'));
      await tester.pumpAndSettle();

      final editButtons = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .where((button) {
            final icon = button.icon;
            return icon is Icon && icon.icon == Icons.edit;
          })
          .toList();

      expect(editButtons.length, 2);
      expect(
        editButtons.where((button) => button.onPressed != null).length,
        1,
      );
      expect(
        editButtons.where((button) => button.onPressed == null).length,
        1,
      );
    },
  );

  testWidgets('cook has readonly edit actions in 7-day table', (tester) async {
    final now = DateTime.now();
    final logs = [
      TemperatureLog(
        id: 'recent',
        sensorId: sensorId,
        temperature: 4.2,
        recordedAt: now.subtract(const Duration(days: 1)),
        isAlert: false,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sensorHistoryProvider(
          sensorId,
          const Duration(hours: 24),
        ).overrideWith((ref) async => const []),
        sensorSevenDayTableProvider(
          sensorId,
        ).overrideWith((ref) async => logs),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentUserProvider.notifier).set(
          Employee(
            id: 'emp-cook',
            fullName: 'Cook',
            role: 'cook',
            isActive: true,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SensorChartScreen(deviceId: sensorId)),
      ),
    );

    await tester.tap(find.text('Tabela 7 dni'));
    await tester.pumpAndSettle();

    final editButtons = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .where((button) {
          final icon = button.icon;
          return icon is Icon && icon.icon == Icons.edit;
        })
        .toList();

    expect(editButtons.length, 1);
    expect(editButtons.single.onPressed, isNull);
  });
}
