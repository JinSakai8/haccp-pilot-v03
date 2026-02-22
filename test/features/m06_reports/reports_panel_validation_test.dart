import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m06_reports/screens/reports_panel_screen.dart';

void main() {
  testWidgets('ReportsPanelScreen blocks temperature generation without sensor',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ReportsPanelScreen(),
        ),
      ),
    );

    expect(find.text('Raportowanie'), findsOneWidget);

    await tester.tap(find.text('Ewidencja Odpadow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejestr Temperatur').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('GENERUJ RAPORT (PDF)'));
    await tester.pump();

    expect(
      find.text('Wybierz urzadzenie przed generowaniem raportu CCP-1.'),
      findsOneWidget,
    );
  });
}

