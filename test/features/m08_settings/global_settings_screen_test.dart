import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:haccp_pilot/features/m08_settings/screens/global_settings_screen.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const GlobalSettingsScreen(),
        ),
        GoRoute(
          path: '/zone-select',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('ZONE_SELECT_SCREEN'))),
        ),
        GoRoute(
          path: '/hub',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HUB_SCREEN'))),
        ),
      ],
    );
  }

  testWidgets('shows explicit error UI when active zone is missing', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Brak aktywnej strefy.'), findsOneWidget);
    expect(
      find.text('Aby otworzyc ustawienia, wybierz strefe ponownie.'),
      findsOneWidget,
    );
    expect(find.text('Wybierz strefe'), findsOneWidget);
    expect(find.text('Powrot do Hub'), findsOneWidget);
  });

  testWidgets('navigates to zone selection after tapping retry CTA', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wybierz strefe'));
    await tester.pumpAndSettle();

    expect(find.text('ZONE_SELECT_SCREEN'), findsOneWidget);
  });
}
