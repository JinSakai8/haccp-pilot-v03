import '../../../../core/models/employee.dart';

class HrAlertsSnapshot {
  HrAlertsSnapshot({
    required this.expired,
    required this.expiring,
    required this.valid,
  });

  final List<Employee> expired;
  final List<Employee> expiring;
  final List<Employee> valid;

  static HrAlertsSnapshot fromEmployees(List<Employee> employees, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final expiringThreshold = today.add(const Duration(days: 30));

    final expired = employees
        .where((e) => e.sanepidExpiry != null && _asDate(e.sanepidExpiry!).isBefore(today))
        .toList();

    final expiring = employees
        .where(
          (e) =>
              e.sanepidExpiry != null &&
              (_asDate(e.sanepidExpiry!).isAtSameMomentAs(today) ||
                  _asDate(e.sanepidExpiry!).isAfter(today)) &&
              (_asDate(e.sanepidExpiry!).isBefore(expiringThreshold) ||
                  _asDate(e.sanepidExpiry!).isAtSameMomentAs(expiringThreshold)),
        )
        .toList();

    final valid = employees
        .where((e) => e.sanepidExpiry != null && _asDate(e.sanepidExpiry!).isAfter(expiringThreshold))
        .toList();

    return HrAlertsSnapshot(
      expired: expired,
      expiring: expiring,
      valid: valid,
    );
  }

  static DateTime _asDate(DateTime value) => DateTime(value.year, value.month, value.day);
}
