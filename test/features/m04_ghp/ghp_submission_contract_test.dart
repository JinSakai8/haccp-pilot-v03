import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m04_ghp/providers/ghp_provider.dart';

void main() {
  group('GHP payload normalization', () {
    test('injects execution date/time and wraps answers', () {
      final normalized = normalizeGhpSubmissionData({
        'uniform': true,
        'hands': false,
        'notes': '  Uwaga testowa  ',
      }, now: DateTime(2026, 2, 27, 8, 5));

      expect(normalized['execution_date'], equals('2026-02-27'));
      expect(normalized['execution_time'], equals('08:05'));
      expect(normalized['answers'], isA<Map<String, dynamic>>());
      expect((normalized['answers'] as Map)['uniform'], isTrue);
      expect((normalized['answers'] as Map)['hands'], isFalse);
      expect(normalized['notes'], equals('Uwaga testowa'));
    });

    test('preserves provided execution fields and answers map', () {
      final normalized = normalizeGhpSubmissionData({
        'execution_date': '2026-02-10',
        'execution_time': '09:30',
        'answers': {'floors': true, 'tables': true},
      });

      expect(normalized['execution_date'], equals('2026-02-10'));
      expect(normalized['execution_time'], equals('09:30'));
      expect((normalized['answers'] as Map)['floors'], isTrue);
      expect((normalized['answers'] as Map)['tables'], isTrue);
      expect(normalized.containsKey('notes'), isFalse);
    });

    test('applies employee and room snapshot payloads', () {
      final mapped = applyGhpReferenceSnapshots(
        answers: {
          'uniform': true,
          'selected_employee': 'emp-1',
          'selected_room': 'room-1',
        },
        employeeId: 'emp-1',
        employeeName: 'Jan Kowalski',
        roomId: 'room-1',
        roomName: 'kuchnia',
      );

      expect(mapped['selected_employee'], equals({
        'id': 'emp-1',
        'name': 'Jan Kowalski',
      }));
      expect(mapped['selected_room'], equals({
        'id': 'room-1',
        'name': 'kuchnia',
      }));
      expect(mapped['uniform'], isTrue);
    });
  });
}
