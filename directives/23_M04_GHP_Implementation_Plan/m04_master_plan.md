# M04 GHP Implementation Master Plan

## 1. Cel Biznesowy
Uspojnienie modulu **m04_ghp** z architektura systemu oraz wymaganiami operacyjnymi HACCP.
Docelowo modul ma:
- zapisywac kompletne checklisty GHP z jawna data/godzina wykonania,
- umozliwiac generowanie i archiwizacje raportow PDF GHP,
- zapewnic podglad raportow i wpisow historycznych,
- zachowac zgodnosc z modelem `haccp_logs` + `generated_reports`.

## 2. Scope Zmian (High-Level)
- **Data/Contract**: rozszerzenie kontraktu danych GHP o pola wykonania i metadane raportowe.
- **Application Layer**: rozszerzenie repozytorium/providerow M04 i M06.
- **UI/UX**: data wykonania w checklistach, szczegoly historii, podglad raportow z archiwum.
- **QA/Audit**: testy kontraktowe, E2E i regresja cross-module.

## 3. Out of Scope
- Refactor innych modulow (M02, M03, M05, M07, M08) poza koniecznymi punktami integracji.
- Redesign global theme/design tokens.
- Zmiany niezwiazane z GHP w auth/router.

## 4. Architektura Docelowa (M04 + M06)
Przeplyw:
1. UI checklisty GHP ->
2. Provider M04 waliduje payload i kontekst strefy ->
3. Repository M04 zapisuje `haccp_logs(category=ghp)` z polami wykonania ->
4. M06 generuje PDF GHP (dataset z `haccp_logs`) ->
5. Upload do `reports` + metadata upsert w `generated_reports` ->
6. Archiwum raportow otwiera podglad/weryfikuje fallback.

## 5. Plan Sprintow
- **Sprint 1 (Analiza)**: inwentaryzacja stanu aktualnego i finalizacja kontraktow.
- **Sprint 2 (Data + Reporting Contract)**: przygotowanie kontraktow DB/storage i mapowania danych.
- **Sprint 3 (Domain + Providers)**: implementacja logiki M04/M06 dla GHP.
- **Sprint 4 (UI + History + Preview)**: wdrozenie ekranow i flow uzytkownika.
- **Sprint 5 (Testy)**: testy automatyczne i manualne E2E.
- **Sprint 6 (Ocena wdrozenia)**: DoD, audit, regresja i decyzja GO/NO-GO.

## 6. Zaleznosci Miedzy Sprintami
- Sprint 2 wymaga artefaktow Sprintu 1 (zatwierdzony kontrakt danych).
- Sprint 3 zalezy od gotowych kontraktow Sprintu 2.
- Sprint 4 zalezy od API/providerow Sprintu 3.
- Sprint 5 obejmuje caly zintegrowany przeplyw po Sprint 4.
- Sprint 6 wymaga kompletnych wynikow Sprintu 5.

## 7. Ryzyka i Guardrails
- **Ryzyko 1: Dryf kontraktu daty wykonania**
  - Guardrail: jednoznaczne pole biznesowe `execution_date` + `execution_time` (lub ustalony odpowiednik) i mapowanie end-to-end.
- **Ryzyko 2: Niespojnosc archiwum PDF (storage vs metadata)**
  - Guardrail: atomowe workflow upload + upsert metadata z retry/fallback.
- **Ryzyko 3: Context Pollution podczas wdrozenia**
  - Guardrail: kazdy sprint posiada osobny dokument i checklisty wejscia/wyjscia.

## 8. Artefakty wyjsciowe
- `m04_sprint_1_analysis.md`
- `m04_sprint_2_data_reporting_contract.md`
- `m04_sprint_3_domain_providers.md`
- `m04_sprint_4_ui_history_preview.md`
- `m04_sprint_5_testing.md`
- `m04_sprint_6_evaluation.md`
