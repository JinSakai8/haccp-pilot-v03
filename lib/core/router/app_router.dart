import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/m01_auth/screens/splash_screen.dart';
import '../../features/m01_auth/screens/pin_pad_screen.dart';
import '../../features/m01_auth/screens/zone_selection_screen.dart';
import '../../features/dashboard/screens/dashboard_hub_screen.dart';
import '../../features/m02_monitoring/screens/temperature_dashboard_screen.dart';
import '../../features/m02_monitoring/screens/alarms_panel_screen.dart';
import '../../features/m02_monitoring/screens/sensor_chart_screen.dart';
import '../../features/m03_gmp/screens/gmp_process_selector_screen.dart';
import '../../features/m03_gmp/screens/meat_roasting_form_screen.dart';
import '../../features/m03_gmp/screens/food_cooling_form_screen.dart';
import '../../features/m03_gmp/screens/delivery_control_form_screen.dart';
import '../../features/m03_gmp/screens/gmp_history_screen.dart';
import '../../features/m04_ghp/screens/ghp_category_selector_screen.dart';
import '../../features/m04_ghp/screens/ghp_checklist_screen.dart';
import '../../features/m05_waste/screens/waste_panel_screen.dart';
import '../../features/m05_waste/screens/waste_registration_form_screen.dart';
import '../../features/m05_waste/screens/haccp_camera_screen.dart';
import '../../features/m05_waste/screens/waste_history_screen.dart';
import '../../features/m08_settings/screens/global_settings_screen.dart';
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
    redirect: (context, state) {
      final employee = ref.read(currentUserProvider);
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
      GoRoute(
        path: '/monitoring/alarms',
        builder: (context, state) => const AlarmsPanelScreen(),
      ),
      GoRoute(
        path: '/monitoring/chart/:deviceId',
        builder: (context, state) {
           final deviceId = state.pathParameters['deviceId'] ?? 'unknown';
           return SensorChartScreen(deviceId: deviceId);
        },
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
      GoRoute(
        path: '/gmp/cooling',
        builder: (context, state) => const FoodCoolingFormScreen(),
      ),
      GoRoute(
        path: '/gmp/delivery',
        builder: (context, state) => const DeliveryControlFormScreen(),
      ),
      GoRoute(
        path: '/gmp/history',
        builder: (context, state) => const GmpHistoryScreen(),
      ),

      // M05 Waste
      GoRoute(
        path: '/waste',
        builder: (context, state) => const WastePanelScreen(),
      ),
      GoRoute(
        path: '/waste/register',
        builder: (context, state) => const WasteRegistrationFormScreen(),
      ),
      GoRoute(
        path: '/waste/camera',
        builder: (context, state) {
           final venueId = ref.read(currentUserProvider)?.venues.firstOrNull ?? 'default'; 
           return HaccpCameraScreen(venueId: venueId);
        },
      ),
      GoRoute(
        path: '/waste/history',
        builder: (context, state) => const WasteHistoryScreen(),
      ),

      // M04 GHP
      GoRoute(
        path: '/ghp',
        builder: (context, state) => const GhpCategorySelectorScreen(),
      ),
      GoRoute(
        path: '/ghp/checklist',
        builder: (context, state) {
          final categoryId = state.extra as String? ?? 'personnel'; // Default fallback
          return GhpChecklistScreen(categoryId: categoryId);
        },
      ),

      // M08 Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const GlobalSettingsScreen(),
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
