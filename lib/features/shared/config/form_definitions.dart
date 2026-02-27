import '../models/form_definition.dart';

class FormDefinitions {
  static final roastingFormDef = FormDefinition(
    title: 'Proces Pieczenia',
    fields: [
      FormFieldConfig(
        id: 'prep_date',
        type: HaccpFieldType.date,
        label: 'Data',
        required: true,
      ),
      FormFieldConfig(
        id: 'product_name',
        type: HaccpFieldType.dropdown,
        label: 'Rodzaj potrawy',
        config: {'source': 'products_table', 'type': 'roasting'},
        required: true,
      ),
      FormFieldConfig(
        id: 'temperature',
        type: HaccpFieldType.stepper,
        label: 'Wartość temperatury [°C]',
        config: {
          'min': 0,
          'max': 200,
          'step': 1,
          'unit': '°C',
          'default': 90.0,
          'warningRange': {'min': 90.0},
        },
        required: true,
      ),
      FormFieldConfig(
        id: 'is_compliant',
        type: HaccpFieldType.toggle,
        label: 'Zgodność z ustaleniami',
        required: true,
      ),
      FormFieldConfig(
        id: 'corrective_actions',
        type: HaccpFieldType.text,
        label: 'Działania korygujące',
        required: false,
        requiredIf: {'field': 'is_compliant', 'value': false},
        visibleIf: {'field': 'is_compliant', 'value': false},
      ),
      FormFieldConfig(
        id: 'signature',
        type: HaccpFieldType.text,
        label: 'Podpis',
        required: true,
      ),
    ],
  );

  static final coolingFormDef = FormDefinition(
    title: 'Proces Chłodzenia',
    fields: [
      FormFieldConfig(
        id: 'product_name',
        type: HaccpFieldType.dropdown,
        label: 'Produkt',
        config: {'source': 'products_table', 'type': 'cooling'},
        required: true,
      ),
      FormFieldConfig(
        id: 'prep_date',
        type: HaccpFieldType.date,
        label: 'Data przygotowania',
        required: true,
      ),
      FormFieldConfig(
        id: 'start_time',
        type: HaccpFieldType.time,
        label: 'Godzina rozpoczęcia',
        required: true,
      ),
      FormFieldConfig(
        id: 'end_time',
        type: HaccpFieldType.time,
        label: 'Godzina zakończenia',
        required: true,
      ),
      FormFieldConfig(
        id: 'temperature',
        type: HaccpFieldType.stepper,
        label: 'Wartość temperatury [°C]',
        config: {'min': -10, 'max': 100, 'default': 4, 'step': 0.1},
        required: true,
      ),
      FormFieldConfig(
        id: 'compliance',
        type: HaccpFieldType.toggle,
        label: 'Zgodność z ustaleniami',
        required: true,
      ),
      FormFieldConfig(
        id: 'corrective_actions',
        type: HaccpFieldType.text,
        label: 'Działania korygujące',
        required: false,
        visibleIf: {'field': 'compliance', 'value': false},
      ),
    ],
  );

  static final deliveryControlFormDef = FormDefinition(
    title: 'Kontrola Dostaw',
    fields: [
      FormFieldConfig(
        id: 'supplier',
        type: HaccpFieldType.text,
        label: 'Dostawca',
        required: true,
      ),
      FormFieldConfig(
        id: 'invoice_no',
        type: HaccpFieldType.text,
        label: 'Nr WZ/Faktury',
        required: true,
      ),
      FormFieldConfig(
        id: 'temp_transport',
        type: HaccpFieldType.stepper,
        label: 'Temp. transportu [°C]',
        config: {'min': -30, 'max': 30, 'default': 4},
        required: true,
      ),
      FormFieldConfig(
        id: 'packaging_ok',
        type: HaccpFieldType.toggle,
        label: 'Stan opakowań OK',
        required: true,
      ),
      FormFieldConfig(
        id: 'expiry_date',
        type: HaccpFieldType.date,
        label: 'Data ważności',
        required: true,
      ),
      FormFieldConfig(
        id: 'pests_detected',
        type: HaccpFieldType.toggle,
        label: 'Ślady szkodników',
        required: true,
      ),
    ],
  );

  static FormDefinition getDefinition(String reportType) {
    switch (reportType) {
      case 'gmp_roasting':
        return roastingFormDef;
      case 'gmp_cooling':
        return coolingFormDef;
      case 'gmp_delivery':
        return deliveryControlFormDef;
      default:
        throw Exception('Nieznany typ raportu: $reportType');
    }
  }
}
