import '../models/form_definition.dart';

class FormDefinitions {
  static final roastingFormDef = FormDefinition(
    title: 'Proces Pieczenia',
    fields: [
      FormFieldConfig(
        id: 'product_name',
        type: HaccpFieldType.dropdown,
        label: 'Produkt',
        config: {
          'source': 'products_table',
          'type': 'roasting'
        },
        required: true,
      ),
      FormFieldConfig(
        id: 'batch_number',
        type: HaccpFieldType.text,
        label: 'Nr Partii',
        required: true,
      ),
      FormFieldConfig(
        id: 'oven_temp',
        type: HaccpFieldType.stepper,
        label: 'Temp. Nastawy Pieca [Â°C]',
        config: {
          'min': 50,
          'max': 300,
          'step': 5,
          'default': 180.0
        },
        required: true,
      ),
      FormFieldConfig(
        id: 'start_time',
        type: HaccpFieldType.time,
        label: 'Czas Start',
        required: true,
      ),
      FormFieldConfig(
        id: 'end_time',
        type: HaccpFieldType.time,
        label: 'Czas Stop',
        required: false,
      ),
      FormFieldConfig(
        id: 'internal_temp',
        type: HaccpFieldType.stepper,
        label: 'Temp. WewnÄ™trzna [Â°C]',
        config: {
          'min': 0, 
          'max': 200, 
          'step': 1, 
          'unit': 'Â°C',
          'default': 90.0,
          'warningRange': {'min': 90.0} // Warning if < 90
        },
        required: true,
      ),
      FormFieldConfig(
        id: 'is_compliant',
        type: HaccpFieldType.toggle,
        label: 'ZgodnoĹ›Ä‡ z ustaleniami',
        required: true,
      ),
      FormFieldConfig(
        id: 'corrective_actions',
        type: HaccpFieldType.text,
        label: 'DziaĹ‚ania korygujÄ…ce',
        required: false,
        requiredIf: {'field': 'is_compliant', 'value': false},
        visibleIf: {'field': 'is_compliant', 'value': false}, // Widoczne tylko gdy ZgodnoĹ›Ä‡ to NIE
      ),
    ],
  );

  static final coolingFormDef = FormDefinition(
    title: 'Proces ChĹ‚odzenia',
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
      FormFieldConfig(id: 'start_time', type: HaccpFieldType.time, label: 'Godzina RozpoczÄ™cia', required: true),
      FormFieldConfig(id: 'end_time', type: HaccpFieldType.time, label: 'Godzina ZakoĹ„czenia', required: true),
      FormFieldConfig(id: 'temperature', type: HaccpFieldType.stepper, label: 'WartoĹ›Ä‡ temperatury [Â°C]', config: {'min': -10, 'max': 100, 'default': 4, 'step': 0.1}, required: true),
      FormFieldConfig(id: 'compliance', type: HaccpFieldType.toggle, label: 'ZgodnoĹ›Ä‡ z ustaleniami', required: true),
      FormFieldConfig(id: 'corrective_actions', type: HaccpFieldType.text, label: 'DziaĹ‚ania korygujÄ…ce', required: false, visibleIf: {'field': 'compliance', 'value': false}),
    ],
  );

  static final deliveryControlFormDef = FormDefinition(
    title: 'Kontrola Dostaw',
    fields: [
      FormFieldConfig(id: 'supplier', type: HaccpFieldType.text, label: 'Dostawca', required: true),
      FormFieldConfig(id: 'invoice_no', type: HaccpFieldType.text, label: 'Nr WZ/Faktury', required: true),
      FormFieldConfig(id: 'temp_transport', type: HaccpFieldType.stepper, label: 'Temp. Transportu [Â°C]', config: {'min': -30, 'max': 30, 'default': 4}, required: true),
      FormFieldConfig(id: 'packaging_ok', type: HaccpFieldType.toggle, label: 'Stan OpakowaĹ„ OK', required: true),
      FormFieldConfig(id: 'expiry_date', type: HaccpFieldType.date, label: 'Data WaĹĽnoĹ›ci', required: true),
      FormFieldConfig(id: 'pests_detected', type: HaccpFieldType.toggle, label: 'Ĺšlady SzkodnikĂłw', required: true),
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

