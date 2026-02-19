import '../models/form_definition.dart';

class FormDefinitions {
  static final roastingFormDef = FormDefinition(
    title: 'Proces Pieczenia',
    fields: [
      FormFieldConfig(
        id: 'product_name',
        type: HaccpFieldType.dropdown,
        label: 'Produkt',
        config: {'options': ['Kurczak Pieczony', 'Uda z Kurczaka', 'Skrzydełka']},
        required: true,
      ),
      FormFieldConfig(
        id: 'internal_temp',
        type: HaccpFieldType.stepper,
        label: 'Temp. Wewnętrzna [°C]',
        config: {
          'min': 0, 
          'max': 120, 
          'step': 1, 
          'unit': '°C',
          'default': 75.0,
          'warningRange': {'min': 75.0} // Warning if < 75
        },
        required: true,
      ),
      FormFieldConfig(
        id: 'comments',
        type: HaccpFieldType.toggle, // Using toggle as a simple OK/Not OK + comment field for now
        label: 'Zgodność organoleptyczna',
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
        config: {
          'source': 'products_table',
          'type': 'cooling'
        }, 
        required: true
      ),
      FormFieldConfig(id: 'prep_date', type: HaccpFieldType.date, label: 'Data Przygotowania', required: true),
      FormFieldConfig(id: 'start_time', type: HaccpFieldType.time, label: 'Godzina Rozpoczęcia', required: true),
      FormFieldConfig(id: 'end_time', type: HaccpFieldType.time, label: 'Godzina Zakończenia', required: true),
      FormFieldConfig(id: 'temperature', type: HaccpFieldType.stepper, label: 'Wartość temperatury [°C]', config: {'min': -10, 'max': 100, 'default': 4, 'step': 0.1}, required: true),
      FormFieldConfig(id: 'compliance', type: HaccpFieldType.toggle, label: 'Zgodność z ustaleniami', required: true),
      FormFieldConfig(id: 'corrective_actions', type: HaccpFieldType.text, label: 'Działania korygujące', required: false),
    ],
  );

  static final deliveryControlFormDef = FormDefinition(
    title: 'Kontrola Dostaw',
    fields: [
      FormFieldConfig(id: 'supplier', type: HaccpFieldType.text, label: 'Dostawca', required: true),
      FormFieldConfig(id: 'invoice_no', type: HaccpFieldType.text, label: 'Nr WZ/Faktury', required: true),
      FormFieldConfig(id: 'temp_transport', type: HaccpFieldType.stepper, label: 'Temp. Transportu [°C]', config: {'min': -30, 'max': 30, 'default': 4}, required: true),
      FormFieldConfig(id: 'packaging_ok', type: HaccpFieldType.toggle, label: 'Stan Opakowań OK', required: true),
      FormFieldConfig(id: 'expiry_date', type: HaccpFieldType.date, label: 'Data Ważności', required: true),
      FormFieldConfig(id: 'pests_detected', type: HaccpFieldType.toggle, label: 'Ślady Szkodników', required: true),
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
