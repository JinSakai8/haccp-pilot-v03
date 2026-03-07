# S1 Findings (M08 Persistence) - Sprint 1

Data: 2026-02-27
Status: Completed (analysis)
Zakres: UI -> Provider -> Repository -> Supabase DB/Storage

## 1. Data Flow Diagram (tekstowy)

1. U¿ytkownik klika `ZAPISZ USTAWIENIA` w `GlobalSettingsScreen`.
2. Ekran pobiera `venueId` z `currentZoneProvider` i uruchamia `_saveSettings(venueId)`.
3. UI normalizuje `nip` przez `trim()`; przy 10 cyfrach przechodzi lokaln¹ walidacjê.
4. Jeœli jest nowe logo (`_newLogoBytes != null`), wywo³ywany jest upload do Storage (`uploadLogoBytes`).
5. Nastêpnie UI wywo³uje `VenueSettingsController.updateSettings(...)`.
6. Provider ustawia `loading`, wykonuje `repository.updateSettings(...)`, potem robi readback `repository.getSettings(venueId)`.
7. Repository buduje payload `updates` i wykonuje `UPDATE public.venues WHERE id = venueId`.
8. DB wymusza constraints (`venues_*_check`) i RLS (`venues_update_manager_owner_kiosk_scope`).
9. W razie sukcesu UI pokazuje `HaccpSuccessOverlay`.

## 2. Root Causes

### Potwierdzone

1. R1 (krytyczny): kontrakt `nip` jest niespójny miêdzy frontem i DB.
- DB dopuszcza `nip = NULL` albo 10 cyfr.
- Front wysy³a `nip` jako `required String` i przekazuje pusty string `''`.
- Skutek: `UPDATE venues` mo¿e zostaæ odrzucony przez `venues_nip_digits_check`.

2. R2 (wysoki): upload logo ma silent fail.
- `uploadLogoBytes` ³apie wyj¹tek i zwraca `null` zamiast propagowaæ b³¹d.
- UI nie odró¿nia awarii uploadu od sytuacji „brak nowego logo”, przez co u¿ytkownik mo¿e dostaæ sukces bez trwa³ej zmiany logo.

3. R3 (wysoki): brak potwierdzonej konfiguracji Storage `branding` (bucket/policies).
- W repo nie ma migracji/policy dla `storage.objects` z `bucket_id = 'branding'`.
- W schemacie bazowym wystêpuj¹ tylko polityki dla `reports`.

4. R4 (wysoki): brak testu E2E save -> readback dla M08 settings.
- S¹ testy mapowania b³êdów i UI fallback, ale brak testu pe³nej œcie¿ki persistence `name/address/logo`.
- SQL smoke test jest manualny (placeholder UUID + `rollback`) i nie zastêpuje testu frontend E2E.

### Hipotezy (do weryfikacji w S2)

1. R5 (œredni): niespójna klasyfikacja b³êdów DB vs Storage w UX.
- Obecne mapowanie skupia siê na constraint/RLS, ale nie ma dedykowanego kodu b³êdu dla awarii uploadu logo.

## 3. Matrix: symptom -> przyczyna -> dowód

| Symptom | Przyczyna | Dowód (plik:linia) |
|---|---|---|
| Zapis ustawieñ czasem „nie trzyma” po odœwie¿eniu | `nip=''` ³amie constraint DB (powinno byæ `NULL`) | `lib/features/m08_settings/screens/global_settings_screen.dart:93` (trim), `:120` (wysy³ka `nip`), `lib/features/m08_settings/repositories/venue_repository.dart:24` (`required String nip`), `:32` (`'nip': nip`), `supabase/migrations/20260224113000_m08_01_venues_settings_columns.sql:55` (`nip is null or 10 cyfr`) |
| Logo nie zapisuje siê, ale brak jasnego b³êdu | Upload t³umi wyj¹tek i zwraca `null` | `lib/features/m08_settings/repositories/venue_repository.dart:47` (upload), `:55-57` (`catch` + `return null`), `lib/features/m08_settings/screens/global_settings_screen.dart:108-113` (fallback na `_logoUrl`) |
| Ryzyko blokady uploadu logo przez polityki storage | Brak migracji/policy dla `branding` | `baseline_schema.sql:1304`, `:1313` (tylko `reports`); brak trafieñ `branding`/`bucket_id='branding'` w `supabase/migrations/*` |
| Brak deterministycznej walidacji scenariusza end-to-end | Brak testu E2E save -> readback | `test/features/m08_settings/m08_sprint3_test.dart` (tylko mapowanie b³êdów/UI), `test/features/m08_settings/global_settings_screen_test.dart` (fallback brak strefy), `supabase/m08_04_settings_smoke_tests.sql:4-10` (placeholder UUID), `:171` (`rollback`) |
| Dostêp do `venues` zale¿ny od kontekstu kiosku | RLS wymaga aktywnego `kiosk_sessions` + roli manager/owner | `lib/features/m01_auth/screens/zone_selection_screen.dart:41-45` (set kiosk context + set zone), `supabase/migrations/20260224114000_m08_02_venues_rls_update_policy.sql:26-50` (policy update manager/owner) |

## 4. Zamro¿ona lista zmian na S2/S3 (no open decisions)

### Sprint 2 (Backend/DB)

1. Potwierdziæ i udokumentowaæ kontrakt `venues.nip`: tylko `NULL` albo 10 cyfr.
2. Dodaæ/zweryfikowaæ bucket `branding` i polityki `storage.objects` (read/write) zgodne z kioskiem/tenantem.
3. Rozszerzyæ smoke SQL o przypadek logo storage (pass/fail) oraz jawne kody b³êdów.
4. Ujednoliciæ format b³êdów backendowych: constraint, RLS, storage denied/not found.

### Sprint 3 (Frontend/API)

1. Zmieniæ kontrakt `nip` w repo/provider na nullable (`String?`) i mapowaæ puste na `null`.
2. Rozdzieliæ flow b³êdów: upload logo vs update `venues`.
3. Usun¹æ silent fail dla uploadu: b³¹d ma byæ propagowany do UI.
4. Dodaæ walidacjê przed submit (`name`, `address`, `nip`) i jawny readback po zapisie.

## 5. DoD Sprint 1 - weryfikacja

- Root cause #1 (NIP `''` vs `NULL`) potwierdzony kontraktem kod/DB i gotowy do odtworzenia testowego.
- Lista zmian dla S2/S3 zamro¿ona, bez otwartych decyzji architektonicznych.
