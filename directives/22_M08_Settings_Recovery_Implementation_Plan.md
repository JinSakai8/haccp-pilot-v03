# M08 Settings Recovery Master Plan

Data: 2026-02-24
Autor: Codex (analiza architektury + plan wykonawczy)
Status: SPRINT 1-4 DOSTARCZONE (manual SQL smoke + rollout pending)

## 1. Zakres analizy
Przeanalizowane dokumenty i kod:
- `directives/00_Architecture_Master_Plan.md`
- `supabase.md`
- `Code_description.MD`
- `UI_description.md`
- `directives/10_m08_settings_and_polish.md`
- `directives/12_final_polish_and_m08.md`
- implementacja `lib/features/m08_settings/*`
- powiazania: router, auth provider, products repository, dashboard

## 2. Stan aktualny M08: co dziala, a co nie

### 2.1 Co dziala
1. Istnieje trasa `/settings` oraz ekran `GlobalSettingsScreen`.
2. Istnieje podstawowe repozytorium danych lokalu (`VenueRepository`).
3. Ekran ma sekcje zgodne z intencja specyfikacji (branding, dane lokalu, sensory, produkty).
4. Dziala przejscie do ekranu zarzadzania produktami (`/settings/products`).
5. Dziala CRUD produktow na poziomie UI (dodanie/edycja/usuniecie).

### 2.2 Co nie dzialalo lub bylo ryzykowne (przed wdrozeniem)
1. Krytyczny bug: ekran `m08_settings` mogl wisiec na loaderze bez konca.
2. Przyczyna techniczna loadera:
- `GlobalSettingsScreen` czekal na `_venueId`.
- `_venueId` ustawiane bylo asynchronicznie przez dodatkowe zapytanie o strefy.
- Brak obslugi bledu i fallbacku.
3. Rozjazd specyfikacja vs kod:
- dokumenty zakladaly `settings_repository.dart`, w kodzie bylo `venue_repository.dart`.
- `UI_description.md` wskazywal `venue_settings` zamiast `venues`.

## 3. Root cause incydentu (wieczne ladowanie)
Najbardziej prawdopodobny scenariusz runtime:
1. Ekran otwiera sie.
2. `_venueId` jest `null`, wiec renderuje sie globalny loader.
3. `_initVenue()` nie ustawia `_venueId`.
4. Brak fallbacku i brak surface bledu -> UI pozostaje stale w loaderze.

Wniosek: naprawa kontraktu kontekstu `venueId` byla warunkiem koniecznym.

## 4. Architektura docelowa M08 (wdrozona)
1. Zrodlo prawdy `venueId`: `currentZoneProvider.venueId`.
2. Ekran ma jawne stany `loading/error/ready`.
3. Brak "cichego" loadera: sa CTA naprawcze.
4. Router ma role guard dla `/settings` i `/settings/*`.
5. Produkty nie maja fallbackow maskujacych problemy DB/RLS.

## 5. Plan sprintow (wykonanie)
1. Sprint 1: Stabilizacja wejscia do M08 i eliminacja wiecznego loadera. ✅
2. Sprint 2: Ujednolicenie kontraktu danych M08 + migracje Supabase. ✅
3. Sprint 3: Domkniecie funkcji settings/products i zgodnosci UX z M09. ✅
4. Sprint 4: Testy E2E, hardening RLS, runbook release + rollback. ✅ (z otwartymi punktami operacyjnymi)

Szczegoly wykonawcze:
- `directives/22_M08_Settings_Recovery_Implementation_Plan/01_Sprint_1_Stabilize_M08_Entry.md`
- `directives/22_M08_Settings_Recovery_Implementation_Plan/02_Sprint_2_Data_Contract_And_DB.md`
- `directives/22_M08_Settings_Recovery_Implementation_Plan/03_Sprint_3_Feature_Completion_And_UX.md`
- `directives/22_M08_Settings_Recovery_Implementation_Plan/04_Sprint_4_QA_Release_Rollback.md`

## 6. Plan zmian Supabase dla M08 (zrealizowane)

### 6.1 Zmiany wdrozone
1. Schemat `venues`:
- `temp_interval int` (default 15, check 5/15/60),
- `temp_threshold numeric` (default 8.0, check 0..15),
- walidacja `nip` (10 cyfr).
2. RLS dla `venues`:
- SELECT scoped do `kiosk_sessions.venue_id`,
- UPDATE tylko dla `manager`/`owner`.
3. RLS dla `products`:
- SELECT: global + lokalny scope kiosku,
- INSERT/UPDATE/DELETE: tylko `manager`/`owner` i tylko we własnym venue.

### 6.2 Migracje
- `supabase/migrations/20260224113000_m08_01_venues_settings_columns.sql`
- `supabase/migrations/20260224114000_m08_02_venues_rls_update_policy.sql`
- `supabase/migrations/20260224115000_m08_03_products_rls_scope_hardening.sql`

## 7. Kryteria akceptacji koncowej (status)
1. Wejscie na `/settings` nie zawiesza sie na loaderze. ✅
2. Brak uprawnien do `/settings` dla `cook/cleaner`. ✅
3. Odczyt i zapis danych lokalu dziala end-to-end (`venues`). ✅
4. Produkty zarzadzane tylko w kontekscie aktualnego venue. ✅
5. UX zgodny z M09: sukces po zapisie i czytelne stany bledu. ✅
6. Testy regresji przechodza dla M08 i nawigacji. ✅

## 8. Uwagi dla junior developera
1. Nie zaczynaj od "dodawania funkcji"; najpierw kontrakt kontekstu `venueId` i stany bledu.
2. Nie zmieniaj wielu warstw naraz: najpierw routing/provider, potem DB, potem UX.
3. Kazda zmiane potwierdzaj scenariuszami manualnymi: manager, cook, brak strefy, blad sieci.

## 9. Artefakty Sprint 4
- `directives/22_M08_Settings_Recovery_Implementation_Plan/05_Sprint_4_Execution_Report_2026-02-24.md`
- `directives/22_M08_Settings_Recovery_Implementation_Plan/06_Release_Checklist.md`
- `directives/22_M08_Settings_Recovery_Implementation_Plan/07_DB_Runbook_Rollback.md`
- `directives/22_M08_Settings_Recovery_Implementation_Plan/08_Sprint_4_Change_Log_2026-02-24.md`

## 10. Otwarte punkty operacyjne
1. Uruchomic `supabase/m08_04_settings_smoke_tests.sql` na staging (real UUID).
2. Przeprowadzic canary rollout i 48h obserwacji.
3. Zamknac sign-off release.
