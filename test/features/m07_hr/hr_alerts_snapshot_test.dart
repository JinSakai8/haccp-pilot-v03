import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/core/models/employee.dart';
import 'package:haccp_pilot/features/m07_hr/utils/hr_alerts_snapshot.dart';

void main() {
  group('HrAlertsSnapshot', () {
    test('classifies employees by sanepid expiry windows', () {
      final now = DateTime(2026, 2, 24);
      final employees = <Employee>[
        Employee(
          id: 'expired',
          fullName: 'Expired User',
          role: 'cook',
          isActive: true,
          sanepidExpiry: DateTime(2026, 2, 1),
        ),
        Employee(
          id: 'expiring',
          fullName: 'Expiring User',
          role: 'cook',
          isActive: true,
          sanepidExpiry: DateTime(2026, 3, 10),
        ),
        Employee(
          id: 'valid',
          fullName: 'Valid User',
          role: 'cook',
          isActive: true,
          sanepidExpiry: DateTime(2026, 4, 30),
        ),
      ];

      final snapshot = HrAlertsSnapshot.fromEmployees(employees, now);

      expect(snapshot.expired.map((e) => e.id), contains('expired'));
      expect(snapshot.expiring.map((e) => e.id), contains('expiring'));
      expect(snapshot.valid.map((e) => e.id), contains('valid'));
    });

    test('includes day+30 in expiring bucket', () {
      final now = DateTime(2026, 2, 24);
      final employee = Employee(
        id: 'boundary',
        fullName: 'Boundary User',
        role: 'cook',
        isActive: true,
        sanepidExpiry: DateTime(2026, 3, 26),
      );

      final snapshot = HrAlertsSnapshot.fromEmployees(<Employee>[employee], now);

      expect(snapshot.expiring.length, 1);
      expect(snapshot.valid, isEmpty);
    });
  });
}
