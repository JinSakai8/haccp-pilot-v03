# S3 Findings (M08 Frontend/API) - Sprint 3

Data: 2026-02-27
Status: Implemented

## Zakres wykonany

1. Kontrakt `nip` po stronie klienta:
- `nip` w repo/provider jest `nullable` (`String?`).
- W submit flow: puste `nip` jest mapowane na `null`.

2. Walidacja payload przed zapisem:
- `name` wymagane,
- `address` wymagane,
- `nip` = 10 cyfr albo puste.

3. Rozdzielenie b³êdów Storage i DB:
- W repo dodano klasyfikacjê b³êdów (`M08SettingsException`):
  - `M08_DB_CONSTRAINT`,
  - `M08_DB_RLS_DENY`,
  - `M08_STORAGE_DENY_OR_NOT_FOUND`.
- UI mapuje komunikaty osobno dla Storage i DB.

4. Brak silent-fail uploadu logo:
- Upload logo nie zwraca ju¿ `null` po b³êdzie, tylko rzuca wyj¹tek.
- UI pokazuje decyzjê operatora: `Sprobuj ponownie` / `Anuluj zapis`.
- Przy anulowaniu zapis ca³oœci jest zatrzymany (brak fa³szywego sukcesu).

5. Readback po zapisie:
- Zachowany przez `VenueSettingsController.updateSettings()` (`getSettings` po `update`).

## Zmienione pliki

- `lib/features/m08_settings/repositories/venue_repository.dart`
- `lib/features/m08_settings/providers/m08_providers.dart`
- `lib/features/m08_settings/screens/global_settings_screen.dart`
- `test/features/m08_settings/m08_sprint3_test.dart`
- `UI_description.md`

## Uwagi

- Nie uruchomiono `flutter test` ani `dart format` w tej sesji, bo narzêdzia `flutter` i `dart` nie s¹ dostêpne w œrodowisku terminala.
