import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m04_ghp/providers/ghp_provider.dart';
import 'package:haccp_pilot/features/m04_ghp/screens/ghp_history_screen.dart';

void main() {
  testWidgets('GHP history shows list and opens details view', (
    WidgetTester tester,
  ) async {
    final logs = <Map<String, dynamic>>[
      <String, dynamic>{
        'form_id': 'ghp_personnel',
        'user_id': 'user-1',
        'created_at': '2026-02-27T08:00:00Z',
        'data': <String, dynamic>{
          'execution_date': '2026-02-27',
          'execution_time': '07:55',
          'answers': <String, dynamic>{'uniform': true, 'hands': false},
          'notes': 'Test detail',
        },
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ghpHistoryProvider.overrideWith((ref) async => logs)],
        child: const MaterialApp(home: GhpHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HIGIENA PERSONELU'), findsOneWidget);
    expect(find.textContaining('Wykonano:'), findsOneWidget);

    await tester.tap(find.text('HIGIENA PERSONELU'));
    await tester.pumpAndSettle();

    expect(find.text('Szczegoly wpisu GHP'), findsOneWidget);
    expect(find.text('Test detail'), findsOneWidget);
    expect(find.text('TAK'), findsOneWidget);
    expect(find.text('NIE'), findsOneWidget);
  });
}
