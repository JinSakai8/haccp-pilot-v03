import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
import '../../features/m04_ghp/screens/ghp_chemicals_screen.dart';
import '../../features/m04_ghp/screens/ghp_history_screen.dart';
import '../../features/m05_waste/screens/waste_panel_screen.dart';
import '../../features/m05_waste/screens/waste_registration_form_screen.dart';
import '../../features/m05_waste/screens/haccp_camera_screen.dart';
import '../../features/m05_waste/screens/waste_history_screen.dart';
import '../../features/m08_settings/screens/global_settings_screen.dart';
import '../../features/m08_settings/screens/manage_products_screen.dart';
import '../../features/m06_reports/screens/reports_panel_screen.dart';
import '../../features/m06_reports/screens/pdf_preview_screen.dart';
import '../../features/m06_reports/screens/ccp3_preview_screen.dart';
import '../../features/m06_reports/screens/saved_reports_screen.dart';
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
  final employee = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isLoggedIn = employee != null;
      final isAuthRoute = state.matchedLocation == RouteNames.splash ||
          state.matchedLocation == RouteNames.login;

      // Guard 1: Not logged in -> force login
      if (!isLoggedIn && !isAuthRoute) return RouteNames.login;

      // Guard 2: Logged in on login page -> hub
      if (isLoggedIn && isAuthRoute) return RouteNames.hub;

      // Guard 3: Role-based (M07 HR, M08 Settings)
      final isManagerRoute = state.matchedLocation.startsWith(RouteNames.hr) ||
          state.matchedLocation.startsWith(RouteNames.settings);
      if (isManagerRoute) {
        if (employee == null || !employee.isManager) {
          return RouteNames.hub; // Silent redirect if not authorized
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const PinPadScreen(),
      ),
      GoRoute(
        path: RouteNames.zoneSelection,
        builder: (context, state) => const ZoneSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.hub,
        builder: (context, state) => const DashboardHubScreen(),
      ),
      
      // M02 Monitoring
      GoRoute(
        path: RouteNames.monitoring,
        builder: (context, state) => const TemperatureDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.monitoringAlarms,
        builder: (context, state) => const AlarmsPanelScreen(),
      ),
      GoRoute(
        path: '${RouteNames.monitoringChartBase}/:deviceId',
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
        path: RouteNames.gmpCooling,
        builder: (context, state) => const FoodCoolingFormScreen(),
      ),
      GoRoute(
        path: RouteNames.gmpDelivery,
        builder: (context, state) => const DeliveryControlFormScreen(),
      ),
      GoRoute(
        path: RouteNames.gmpHistory,
        builder: (context, state) => const GmpHistoryScreen(),
      ),

      // M05 Waste
      GoRoute(
        path: RouteNames.waste,
        builder: (context, state) => const WastePanelScreen(),
      ),
      GoRoute(
        path: RouteNames.wasteRegister,
        builder: (context, state) => const WasteRegistrationFormScreen(),
      ),
      GoRoute(
        path: RouteNames.wasteCamera,
        builder: (context, state) {
           final venueId = employee?.venues.firstOrNull ?? 'default'; 
           return HaccpCameraScreen(venueId: venueId);
        },
      ),
      GoRoute(
        path: RouteNames.wasteHistory,
        builder: (context, state) => const WasteHistoryScreen(),
      ),

      // M04 GHP
      GoRoute(
        path: RouteNames.ghp,
        builder: (context, state) => const GhpCategorySelectorScreen(),
      ),
      GoRoute(
        path: RouteNames.ghpChecklist,
        builder: (context, state) {
          final categoryId = state.extra as String? ?? 'personnel'; // Default fallback
          return GhpChecklistScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: RouteNames.ghpHistory,
        builder: (context, state) => const GhpHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.ghpChemicals,
        builder: (context, state) => const GhpChemicalsScreen(),
      ),

      // M08 Settings
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const GlobalSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.settingsProducts,
        builder: (context, state) => const ManageProductsScreen(),
      ),

      // M06 Reports
      GoRoute(
        path: RouteNames.reports,
        builder: (context, state) => const ReportsPanelScreen(),
      ),
      GoRoute(
        path: RouteNames.reportsPreviewLocal,
        builder: (context, state) {
          final path = state.extra as String;
          return PdfPreviewScreen(filePath: path);
        },
      ),
      GoRoute(
        path: RouteNames.reportsPreviewCcp3,
        builder: (context, state) {
          final dateStr = state.uri.queryParameters['date'] ?? DateTime.now().toIso8601String().split('T')[0];
          return Ccp3PreviewScreen(date: DateTime.tryParse(dateStr) ?? DateTime.now());
        },
      ),
      GoRoute(
        path: RouteNames.reportsHistory,
        builder: (context, state) => const SavedReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.reportsDrive,
        builder: (context, state) => const DriveStatusScreen(),
      ),

      // M07 HR
      GoRoute(
        path: RouteNames.hr,
        builder: (context, state) => const HrDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.hrList,
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: RouteNames.hrAdd,
        builder: (context, state) => const AddEmployeeScreen(),
      ),
      GoRoute(
        path: '${RouteNames.hrEmployeeBase}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeProfileScreen(employeeId: id);
        },
      ),
    ],
  );
}
