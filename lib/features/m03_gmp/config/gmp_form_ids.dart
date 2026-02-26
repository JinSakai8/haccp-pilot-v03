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
  gmpMeatRoastingFormId: 'Pieczenie Mięsa',
  gmpFoodCoolingFormId: 'Schładzanie żywności',
  gmpDeliveryControlFormId: 'Kontrola Dostaw',
};

const String gmpHistoryPreviewUnavailableMessage =
    'Podgląd dla tego typu wpisu nie jest dostępny.';

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

String? gmpHistoryPreviewRoute({
  required String rawFormId,
  required DateTime anchorDate,
}) {
  final normalized = normalizeGmpFormId(rawFormId);
  final year = anchorDate.year.toString().padLeft(4, '0');
  final month = anchorDate.month.toString().padLeft(2, '0');
  final day = anchorDate.day.toString().padLeft(2, '0');
  final dateStr = '$year-$month-$day';

  if (normalized == gmpFoodCoolingFormId) {
    return '/reports/preview/ccp3?date=$dateStr';
  }

  if (normalized == gmpMeatRoastingFormId) {
    return '/reports/preview/ccp2?date=$dateStr';
  }

  return null;
}
