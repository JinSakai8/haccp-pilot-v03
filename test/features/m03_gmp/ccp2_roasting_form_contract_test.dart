import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/shared/config/form_definitions.dart';

void main() {
  group('CCP2 roasting form contract', () {
    test('contains expected fields and excludes legacy fields', () {
      final fields = FormDefinitions.roastingFormDef.fields;
      final ids = fields.map((f) => f.id).toList();

      expect(
        ids,
        equals(<String>[
          'prep_date',
          'product_name',
          'temperature',
          'is_compliant',
          'corrective_actions',
          'signature',
        ]),
      );
      expect(ids, isNot(contains('batch_number')));
      expect(ids, isNot(contains('internal_temp')));
      expect(ids, isNot(contains('oven_temp')));
      expect(ids, isNot(contains('start_time')));
      expect(ids, isNot(contains('end_time')));
    });
  });
}
