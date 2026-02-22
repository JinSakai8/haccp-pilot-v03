const String gmpFoodCoolingFormId = 'food_cooling';
const String gmpMeatRoastingFormId = 'meat_roasting';
const String gmpDeliveryControlFormId = 'delivery_control';

const String gmpMeatRoastingLegacyFormId = 'meat_roasting_daily';
const String gmpDeliveryControlLegacyFormId = 'delivery_control_daily';

const List<String> gmpCanonicalFormIds = <String>[
  gmpFoodCoolingFormId,
  gmpMeatRoastingFormId,
  gmpDeliveryControlFormId,
];

const Map<String, String> gmpLegacyToCanonicalFormIds = <String, String>{
  gmpMeatRoastingLegacyFormId: gmpMeatRoastingFormId,
  gmpDeliveryControlLegacyFormId: gmpDeliveryControlFormId,
};

const Map<String, String> gmpProcessLabels = <String, String>{
  gmpMeatRoastingFormId: 'Pieczenie Mięs',
  gmpFoodCoolingFormId: 'Schładzanie Żywności',
  gmpDeliveryControlFormId: 'Kontrola Dostaw',
};

String normalizeGmpFormId(String formId) {
  return gmpLegacyToCanonicalFormIds[formId] ?? formId;
}

List<String> gmpHistoryCompatibleFormIds(String formId) {
  final normalized = normalizeGmpFormId(formId);
  switch (normalized) {
    case gmpMeatRoastingFormId:
      return <String>[gmpMeatRoastingFormId, gmpMeatRoastingLegacyFormId];
    case gmpDeliveryControlFormId:
      return <String>[gmpDeliveryControlFormId, gmpDeliveryControlLegacyFormId];
    default:
      return <String>[normalized];
  }
}
