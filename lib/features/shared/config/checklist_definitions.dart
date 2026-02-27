import '../../shared/models/form_definition.dart';

class ChecklistDefinitions {
  static const List<String> ghpChemicalsCatalog = <String>[
    'Plyn do naczyn (L)',
    'Srodek do podlog (L)',
    'Dezynfekcja rak (L)',
    'Odtluszczacz (L)',
    'Plyn do szyb (L)',
  ];

  static final Map<String, FormDefinition> ghpDefinitions = {
    'personnel': FormDefinition(
      fields: [
        FormFieldConfig(
          id: 'selected_employee',
          type: HaccpFieldType.dropdown,
          label: 'Pracownik',
          required: true,
          config: const {'source': 'employees_table'},
        ),
        FormFieldConfig(
          id: 'uniform',
          type: HaccpFieldType.toggle,
          label: 'Czysty ubiór roboczy',
          required: true,
        ),
        FormFieldConfig(
          id: 'jewelry',
          type: HaccpFieldType.toggle,
          label: 'Brak biżuterii',
          required: true,
        ),
        FormFieldConfig(
          id: 'hair',
          type: HaccpFieldType.toggle,
          label: 'Włosy osłonięte (czepek/siatka)',
          required: true,
        ),
        FormFieldConfig(
          id: 'hands',
          type: HaccpFieldType.toggle,
          label: 'Ręce umyte i zdezynfekowane',
          required: true,
        ),
        FormFieldConfig(
          id: 'health',
          type: HaccpFieldType.toggle,
          label: 'Brak objawów chorobowych',
          required: true,
        ),
      ],
    ),
    'rooms': FormDefinition(
      fields: [
        FormFieldConfig(
          id: 'selected_room',
          type: HaccpFieldType.dropdown,
          label: 'Pomieszczenie',
          required: true,
          config: const {'source': 'products_table', 'type': 'rooms'},
        ),
        FormFieldConfig(
          id: 'floors',
          type: HaccpFieldType.toggle,
          label: 'Czystość podłóg',
          required: true,
        ),
        FormFieldConfig(
          id: 'tables',
          type: HaccpFieldType.toggle,
          label: 'Czystość blatów roboczych',
          required: true,
        ),
        FormFieldConfig(
          id: 'bins',
          type: HaccpFieldType.toggle,
          label: 'Kosze opróżnione',
          required: true,
        ),
        FormFieldConfig(
          id: 'sinks',
          type: HaccpFieldType.toggle,
          label: 'Zlew / umywalka czyste',
          required: true,
        ),
        FormFieldConfig(
          id: 'ventilation',
          type: HaccpFieldType.toggle,
          label: 'Kratki wentylacyjne czyste',
          required: true,
        ),
      ],
    ),
    'maintenance': FormDefinition(
      fields: [
        FormFieldConfig(
          id: 'oven',
          type: HaccpFieldType.toggle,
          label: 'Piec konwekcyjny',
          required: true,
        ),
        FormFieldConfig(
          id: 'fridge_1',
          type: HaccpFieldType.toggle,
          label: 'Chłodnia #1',
          required: true,
        ),
        FormFieldConfig(
          id: 'fridge_2',
          type: HaccpFieldType.toggle,
          label: 'Chłodnia #2',
          required: true,
        ),
        FormFieldConfig(
          id: 'fryer',
          type: HaccpFieldType.toggle,
          label: 'Frytownica',
          required: true,
        ),
        FormFieldConfig(
          id: 'grill',
          type: HaccpFieldType.toggle,
          label: 'Toster/Grill',
          required: true,
        ),
        FormFieldConfig(
          id: 'thermomix',
          type: HaccpFieldType.toggle,
          label: 'Termomix',
          required: true,
        ),
        FormFieldConfig(
          id: 'dishwasher',
          type: HaccpFieldType.toggle,
          label: 'Zmywarka',
          required: true,
        ),
      ],
    ),
    'chemicals': FormDefinition(
      fields: [
        FormFieldConfig(
          id: 'name',
          type: HaccpFieldType.text,
          label: 'Nazwa środka',
          required: true,
        ),
        FormFieldConfig(
          id: 'amount',
          type: HaccpFieldType.stepper,
          label: 'Ilość / Stężenie',
          required: true,
        ),
        FormFieldConfig(
          id: 'target',
          type: HaccpFieldType.dropdown,
          label: 'Przeznaczenie',
          required: true,
          config: const {
            'options': ['Podłogi', 'Blaty', 'Sprzęt', 'Ręce'],
          },
        ),
      ],
    ),
  };
}
