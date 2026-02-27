import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/features/m04_ghp/screens/ghp_checklist_screen.dart';

void main() {
  testWidgets('GHP checklist requires execution date/time before submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: GhpChecklistScreen(categoryId: 'personnel')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wybierz date'), findsOneWidget);
    expect(find.text('Wybierz godzine'), findsOneWidget);
    expect(find.text('UZUPELNIJ POLA'), findsOneWidget);
  });

  testWidgets('GHP personnel checklist renders employee selector', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: GhpChecklistScreen(categoryId: 'personnel')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pracownik'), findsOneWidget);
  });

  testWidgets('GHP rooms checklist renders room selector', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: GhpChecklistScreen(categoryId: 'rooms')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pomieszczenie'), findsOneWidget);
  });
}
