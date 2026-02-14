import '../models/form_definition.dart';

class FormDefinitions {
  static final roastingFormDef = FormDefinition(
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

  static FormDefinition getDefinition(String reportType) {
    switch (reportType) {
      case 'gmp_roasting':
        return roastingFormDef;
      default:
        throw Exception('Nieznany typ raportu: $reportType');
    }
  }
}
