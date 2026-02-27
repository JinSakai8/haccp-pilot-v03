import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m03_gmp/config/gmp_form_ids.dart';

void main() {
  group('GMP history preview navigation smoke', () {
    final anchorDate = DateTime(2026, 2, 26);

    test('routes cooling form to CCP3 preview', () {
      final route = gmpHistoryPreviewRoute(
        rawFormId: gmpFoodCoolingFormId,
        anchorDate: anchorDate,
      );

      expect(route, equals('/reports/preview/ccp3?date=2026-02-26'));
    });

    test('routes roasting form to CCP2 preview', () {
      final route = gmpHistoryPreviewRoute(
        rawFormId: gmpMeatRoastingFormId,
        anchorDate: anchorDate,
      );

      expect(route, equals('/reports/preview/ccp2?date=2026-02-26'));
    });

    test('routes legacy roasting form to CCP2 preview', () {
      final route = gmpHistoryPreviewRoute(
        rawFormId: gmpMeatRoastingLegacyFormId,
        anchorDate: anchorDate,
      );

      expect(route, equals('/reports/preview/ccp2?date=2026-02-26'));
    });

    test('returns null for unsupported process type', () {
      final route = gmpHistoryPreviewRoute(
        rawFormId: gmpDeliveryControlFormId,
        anchorDate: anchorDate,
      );

      expect(route, isNull);
    });
  });
}
