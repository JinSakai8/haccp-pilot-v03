# Plan Implementacji M02 -> Tabela 7 Dni + Edycja Pomiarow (Index)

Ten pakiet zawiera plan wykonawczy dla junior developera: nowy widok tabelaryczny 7 dni (per sensor) oraz edycja temperatury z kontrola uprawnien i ograniczeniem czasowym.

## Cel biznesowy
- Umozliwic operatorowi szybki przeglad wszystkich pomiarow z ostatnich 7 dni dla jednego sensora.
- Umozliwic korekte temperatury bezposrednio z tabeli.

## Decyzje zamrozone
- Model edycji: nadpisanie rekordu (bez osobnej historii wersji).
- Zakres tabeli: osobny widok per sensor.
- Uprawnienia edycji: tylko `manager` i `owner`.
- Edytowalne pole: tylko temperatura.
- Okno edycji: do 7 dni od `recorded_at`.

## Zakres zmian technicznych
- M02 UI: 4. tryb w `SensorChartScreen` -> `Tabela 7 dni`.
- M02 Data Layer: nowy read path tabeli i akcja edycji temperatury.
- DB: RPC + hardening RLS dla `temperature_logs`.
- Dokumentacja release: runbook rollback i checklista wdrozenia.

## Podzial na pliki
1. `directives/20_M02_Table_7D_Edit_Implementation_Plan/01_Context_And_Decisions.md`
2. `directives/20_M02_Table_7D_Edit_Implementation_Plan/02_Sprint_0_Baseline.md`
3. `directives/20_M02_Table_7D_Edit_Implementation_Plan/03_Sprint_1_UI_Read_Table.md`
4. `directives/20_M02_Table_7D_Edit_Implementation_Plan/04_Sprint_2_Inline_Edit.md`
5. `directives/20_M02_Table_7D_Edit_Implementation_Plan/05_Sprint_3_DB_RLS_RPC.md`
6. `directives/20_M02_Table_7D_Edit_Implementation_Plan/06_Sprint_4_Testing_QA_Release.md`
7. `directives/20_M02_Table_7D_Edit_Implementation_Plan/07_DB_Runbook_Rollback.md`
8. `directives/20_M02_Table_7D_Edit_Implementation_Plan/08_Release_Checklist.md`

## Kolejnosc pracy
1. Baseline i kontrakt.
2. UI read path tabeli.
3. Inline edit po stronie aplikacji.
4. DB hardening + RPC.
5. Testy, QA i rollout canary.

## Definicja sukcesu
- Uzytkownik widzi tabele 7 dni dla sensora.
- `manager/owner` moga edytowac temperature tylko do 7 dni.
- Backend blokuje edycje spoza roli/kontekstu/okna czasu.
- Brak regresji wykresow i panelu alarmow.

## Status sprintow
- Sprint 0 (Baseline i kontrakt): CLOSED (2026-02-23)
- Sprint 1 (UI + Read Path tabeli 7 dni): CLOSED (2026-02-23)
- Sprint 2 (Inline Edit + autoryzacja aplikacyjna): CLOSED (2026-02-23)
- Sprint 3 (DB Hardening: RLS + RPC): CLOSED (2026-02-23)
- Sprint 4 (Testing, QA, Release): IN PROGRESS (2026-02-23)
