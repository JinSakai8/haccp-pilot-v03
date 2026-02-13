import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/m01_auth/screens/splash_screen.dart';
import '../../features/m01_auth/screens/pin_pad_screen.dart';
import '../../features/m01_auth/screens/zone_selection_screen.dart';
import '../../features/dashboard/screens/dashboard_hub_screen.dart';
import '../../features/m02_monitoring/screens/temperature_dashboard_screen.dart';
import '../../core/widgets/placeholder_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PinPadScreen(),
      ),
      GoRoute(
        path: '/zone-select',
        builder: (context, state) => const ZoneSelectionScreen(),
      ),
      GoRoute(
        path: '/hub',
        builder: (context, state) => const DashboardHubScreen(),
      ),
      
      // M02 Monitoring
      GoRoute(
        path: '/monitoring',
        builder: (context, state) => const TemperatureDashboardScreen(),
      ),
      
      // M03 GMP (WIP)
      GoRoute(
        path: '/gmp',
        builder: (context, state) => const PlaceholderScreen(title: "Procesy GMP"),
      ),
    ],
  );
}
