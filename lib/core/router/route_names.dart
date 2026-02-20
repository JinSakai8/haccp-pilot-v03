class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String zoneSelection = '/zone-select';

  static const String hub = '/hub';

  // M02 Monitoring
  static const String monitoring = '/monitoring';
  static const String monitoringChartBase = '/monitoring/chart';
  static const String monitoringAlarms = '/monitoring/alarms';

  // M03 GMP
  static const String gmp = '/gmp';
  static const String gmpRoasting = '/gmp/roasting';
  static const String gmpCooling = '/gmp/cooling';
  static const String gmpDelivery = '/gmp/delivery';
  static const String gmpHistory = '/gmp/history';

  // M04 GHP
  static const String ghp = '/ghp';
  static const String ghpChecklist = '/ghp/checklist';
  static const String ghpChemicals = '/ghp/chemicals';
  static const String ghpHistory = '/ghp/history';

  // M05 Waste
  static const String waste = '/waste';
  static const String wasteRegister = '/waste/register';
  static const String wasteCamera = '/waste/camera';
  static const String wasteHistory = '/waste/history';

  // M06 Reports
  static const String reports = '/reports';
  static const String reportsPreviewLocal = '/reports/preview/local';
  static const String reportsPreviewCcp3 = '/reports/preview/ccp3';
  static const String reportsHistory = '/reports/history';
  static const String reportsDrive = '/reports/drive';

  // M07 HR
  static const String hr = '/hr';
  static const String hrList = '/hr/list';
  static const String hrAdd = '/hr/add';
  static const String hrEmployeeBase = '/hr/employee';

  // M08 Settings
  static const String settings = '/settings';
  static const String settingsProducts = '/settings/products';

  // Route helpers
  static String monitoringChart(String deviceId) =>
      '$monitoringChartBase/$deviceId';

  static String hrEmployee(String employeeId) =>
      '$hrEmployeeBase/$employeeId';

  static String reportsPreviewCcp3WithDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return '$reportsPreviewCcp3?date=$dateStr';
  }
}
