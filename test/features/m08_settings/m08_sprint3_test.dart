import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m08_settings/screens/global_settings_screen.dart';
import 'package:haccp_pilot/features/m08_settings/screens/manage_products_screen.dart';
import 'package:haccp_pilot/features/shared/repositories/products_repository.dart';

void main() {
  test('maps settings constraint errors to readable messages', () {
    expect(
      mapSettingsErrorMessage(
        Exception('violates check constraint venues_temp_threshold_check'),
      ),
      'Prog alarmowy musi byc w zakresie 0-15.',
    );
    expect(
      mapSettingsErrorMessage(Exception('row-level security policy violation')),
      'Brak uprawnien do zapisu ustawien lokalu.',
    );
  });

  testWidgets('shows empty state when no products exist in category', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        productsProvider('cooling').overrideWith((ref) async => const []),
        productsProvider('roasting').overrideWith((ref) async => const []),
        productsProvider('general').overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ManageProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Brak produktow'), findsOneWidget);
    expect(
      find.text('Dodaj pierwszy produkt w tej kategorii.'),
      findsOneWidget,
    );
  });
}
