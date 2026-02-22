import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m03_gmp/config/gmp_form_ids.dart';

void main() {
  group('GMP form_id contract', () {
    test('canonical form ids are fixed and complete', () {
      expect(
        gmpCanonicalFormIds,
        equals(<String>[
          gmpFoodCoolingFormId,
          gmpMeatRoastingFormId,
          gmpDeliveryControlFormId,
        ]),
      );
    });

    test('legacy ids map to canonical ids', () {
      expect(
        gmpLegacyToCanonicalFormIds,
        equals(<String, String>{
          gmpMeatRoastingLegacyFormId: gmpMeatRoastingFormId,
          gmpDeliveryControlLegacyFormId: gmpDeliveryControlFormId,
        }),
      );
    });

    test('history filter for roasting includes legacy and canonical ids', () {
      expect(
        gmpHistoryCompatibleFormIds(gmpMeatRoastingFormId),
        equals(<String>[gmpMeatRoastingFormId, gmpMeatRoastingLegacyFormId]),
      );
      expect(
        gmpHistoryCompatibleFormIds(gmpMeatRoastingLegacyFormId),
        equals(<String>[gmpMeatRoastingFormId, gmpMeatRoastingLegacyFormId]),
      );
    });

    test('history filter for delivery includes legacy and canonical ids', () {
      expect(
        gmpHistoryCompatibleFormIds(gmpDeliveryControlFormId),
        equals(<String>[gmpDeliveryControlFormId, gmpDeliveryControlLegacyFormId]),
      );
      expect(
        gmpHistoryCompatibleFormIds(gmpDeliveryControlLegacyFormId),
        equals(<String>[gmpDeliveryControlFormId, gmpDeliveryControlLegacyFormId]),
      );
    });

    test('cooling has no legacy alias', () {
      expect(
        gmpHistoryCompatibleFormIds(gmpFoodCoolingFormId),
        equals(<String>[gmpFoodCoolingFormId]),
      );
    });
  });
}
