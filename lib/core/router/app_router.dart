import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/m01_auth/screens/splash_screen.dart';
import '../../features/m01_auth/screens/pin_pad_screen.dart';
import '../../features/m01_auth/screens/zone_selection_screen.dart';
import '../../features/dashboard/screens/dashboard_hub_screen.dart';
import '../../features/m02_monitoring/screens/temperature_dashboard_screen.dart';
import '../../features/m03_gmp/screens/gmp_process_selector_screen.dart';
import '../../features/m03_gmp/screens/meat_roasting_form_screen.dart';
import '../../features/m06_reports/screens/reports_panel_screen.dart';
import '../../features/m06_reports/screens/pdf_preview_screen.dart';
import '../../features/m06_reports/screens/drive_status_screen.dart';
import '../../features/m07_hr/screens/hr_dashboard_screen.dart';
import '../../features/m07_hr/screens/employee_list_screen.dart';
import '../../features/m07_hr/screens/add_employee_screen.dart';
import '../../features/m07_hr/screens/employee_profile_screen.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
      final employee = ref.read(currentEmployeeProvider);
      final isLoggedIn = employee != null;
      final isAuthRoute = state.matchedLocation == '/' || state.matchedLocation == '/login';

      // Guard 1: Not logged in -> force login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Guard 2: Logged in on login page -> hub
      if (isLoggedIn && isAuthRoute) return '/hub';

      // Guard 3: Role-based (M07 HR)
      final isHrRoute = state.matchedLocation.startsWith('/hr');
      if (isHrRoute) {
        if (employee == null || !employee.isManager) {
          return '/hub'; // Silent redirect if not authorized
        }
      }

      return null;
    },
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
      
      // M03 GMP
      GoRoute(
        path: RouteNames.gmp,
        builder: (context, state) => const GmpProcessSelectorScreen(),
      ),
      GoRoute(
        path: RouteNames.gmpRoasting,
        builder: (context, state) => const MeatRoastingFormScreen(),
      ),

      // M06 Reports
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPanelScreen(),
      ),
      GoRoute(
        path: '/reports/preview/local',
        builder: (context, state) {
          final path = state.extra as String;
          return PdfPreviewScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/reports/drive',
        builder: (context, state) => const DriveStatusScreen(),
      ),

      // M07 HR
      GoRoute(
        path: '/hr',
        builder: (context, state) => const HrDashboardScreen(),
      ),
      GoRoute(
        path: '/hr/list',
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: '/hr/add',
        builder: (context, state) => const AddEmployeeScreen(),
      ),
      GoRoute(
        path: '/hr/employee/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeProfileScreen(employeeId: id);
        },
      ),
    ],
  );
}
