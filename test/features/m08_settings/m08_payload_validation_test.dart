import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m08_settings/screens/global_settings_screen.dart';

void main() {
  group('M08 payload validation', () {
    test('allows empty NIP by normalizing to null', () {
      expect(normalizeNipOrNull(''), isNull);
      expect(normalizeNipOrNull('   '), isNull);
    });

    test('keeps valid NIP value after normalization', () {
      expect(normalizeNipOrNull('1234567890'), equals('1234567890'));
      expect(normalizeNipOrNull(' 1234567890 '), equals('1234567890'));
    });

    test('rejects missing required fields', () {
      expect(
        validateM08SettingsPayload(
          name: '',
          address: 'Adres',
          nip: null,
        ),
        equals('Nazwa lokalu jest wymagana.'),
      );
      expect(
        validateM08SettingsPayload(
          name: 'Lokal',
          address: ' ',
          nip: null,
        ),
        equals('Adres lokalu jest wymagany.'),
      );
    });

    test('rejects malformed NIP and accepts valid or null', () {
      expect(
        validateM08SettingsPayload(
          name: 'Lokal',
          address: 'Adres',
          nip: '123',
        ),
        equals('NIP musi zawierac dokladnie 10 cyfr.'),
      );
      expect(
        validateM08SettingsPayload(
          name: 'Lokal',
          address: 'Adres',
          nip: '1234567890',
        ),
        isNull,
      );
      expect(
        validateM08SettingsPayload(
          name: 'Lokal',
          address: 'Adres',
          nip: null,
        ),
        isNull,
      );
    });
  });
}
