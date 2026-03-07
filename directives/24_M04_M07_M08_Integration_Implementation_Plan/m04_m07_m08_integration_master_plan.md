# M04-M07-M08 Integration Master Plan

## 1. Cel Biznesowy i North Star
Celem jest integracja modulow M04 GHP, M07 HR i M08 Settings tak, aby checklisty GHP korzystaly z aktualnych danych referencyjnych (pracownicy, pomieszczenia) bez naruszenia architektury `Screen -> Provider -> Repository -> Supabase` i aktualnego modelu RLS kiosk-scope.

North Star:
- M04 Personel: wybor pracownika z M07.
- M08 Settings: zarzadzanie slownikiem pomieszczen.
- M04 Pomieszczenia: wybor pomieszczenia z M08.
- Historia M04 pozostaje audytowalna mimo zmian referencji w M07/M08.

## 2. Decyzje Architektoniczne
### 2.1 Przechowywanie pomieszczen
Wybrano rozszerzenie istniejacego modelu `public.products.type` o wartosc `rooms`.

Uzasadnienie:
- Reuse gotowego CRUD, RLS i providerow M08.
- Brak nowej tabeli i dodatkowych policy drift.
- Spójny wzorzec z `cooling` i `roasting`.

Odrzucone:
- Osobna tabela `rooms`: wieksza zlozonosc migracyjna i utrzymaniowa.
- JSONB w `venues`: gorsza walidowalnosc i queryability.

### 2.2 Kontrakt snapshotow w M04
W `haccp_logs.data.answers` zapisywany jest snapshot `id + name`:
- `selected_employee: { id, name }`
- `selected_room: { id, name }`

Uzasadnienie:
- Historia pozostaje czytelna po zmianach/usunieciach encji.
- Zachowana mozliwosc technicznego mapowania po ID.

## 3. Granice Modulow
- M07 HR: zrodlo listy pracownikow (aktywni + scope).
- M08 Settings: zrodlo listy pomieszczen (`products.type='rooms'`).
- M04 GHP: konsument danych, zapis snapshotow i historia.

## 4. Spis Sprintow
1. `integration_sprint_1_analysis.md`
2. `integration_sprint_2_db_and_settings.md`
3. `integration_sprint_3_ghp_forms.md`
4. `integration_sprint_4_testing.md`
5. `integration_sprint_5_evaluation.md`

## 5. Zaleznosci Sprintow
- Sprint 2 wymaga zamknietej analizy Sprintu 1.
- Sprint 3 wymaga gotowej migracji/seed i UI M08 z `rooms`.
- Sprint 4 wymaga zintegrowanych zmian M04+M07+M08.
- Sprint 5 wymaga wynikow testow i decyzji release.

## 6. Ryzyka i Guardrails
- Ryzyko: regresja list produktow.
  Guardrail: brak zmian semantyki `cooling/roasting/general`, test regresji tabow.
- Ryzyko: utrata czytelnosci historii po dezaktywacji pracownika.
  Guardrail: snapshot `id+name` i render fallback po `name`.
- Ryzyko: naruszenie RLS dla produktów.
  Guardrail: reuse obecnych `products_*_kiosk_scope`, brak nowych policy.

## 7. Artefakty Wdrozeniowe
- Migracja: `supabase/migrations/20260227150000_m08_05_rooms_seed_and_type_guard.sql`
- Katalog planu: `directives/24_M04_M07_M08_Integration_Implementation_Plan/`
