import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haccp_pilot/main.dart';

void main() {
  testWidgets('App starts and shows splash branding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: HaccpPilotApp()));

    expect(find.text('HACCP Pilot'), findsOneWidget);
    expect(find.text('v03-00'), findsOneWidget);

    // Splash auto-redirect uses a 2s timer; advance fake time to avoid pending timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
