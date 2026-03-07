import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m02_monitoring/screens/temperature_dashboard_screen.dart';

void main() {
  testWidgets('TemperatureDashboardScreen shows message when no zone selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TemperatureDashboardScreen(),
        ),
      ),
    );

    expect(find.text('Monitoring Temperatur'), findsOneWidget);
    expect(find.text('Brak wybranej strefy'), findsOneWidget);
  });
}
