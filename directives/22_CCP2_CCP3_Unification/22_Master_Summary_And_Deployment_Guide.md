# CCP2 + CCP3 Unification Master Plan

Data: 2026-02-26
Zakres: M03 GMP Historia + M06 Raporty + Archiwum + DB (`generated_reports`)

## 1. Cel
Doprowadzić CCP2 (pieczenie) i CCP3 (chłodzenie) do pełnej spójności działania w obu miejscach:
1. `M03 > GMP Historia wpisów`
2. `M06 > Raporty + Archiwum`

## 2. Efekt docelowy
1. Klik wpisu CCP2 w GMP Historii otwiera podgląd miesięcznego raportu CCP2.
2. Klik wpisu CCP3 w GMP Historii otwiera podgląd miesięcznego raportu CCP3.
3. W M06 oba typy raportów (CCP2, CCP3) działają miesięcznie.
4. Archiwum M06 pokazuje i otwiera oba typy raportów dla aktywnego `venue_id`.
5. Legacy rekordy CCP3 bez `venue_id` są naprawione przez backfill DB.

## 3. Struktura sprintów
1. Sprint 0: Baseline i audyt stanu.
2. Sprint 1: Kontrakt docelowy i decyzje architektoniczne.
3. Sprint 2: M03 GMP Historia (nawigacja + UX).
4. Sprint 3: M06 CCP3 monthly + spójność z CCP2.
5. Sprint 4: DB backfill + bezpieczeństwo + operacyjność.
6. Sprint 5: Testy pełne (unit/widget/integration/SQL).
7. Sprint 6: Review wdrożenia i decyzja GO/NO-GO.

## 4. Kolejność wdrażania (instrukcja wykonawcza)
1. Zrealizuj Sprint 0 i 1 bez modyfikacji feature logic.
2. Wdróż Sprint 2 i 3 razem na osobnym branchu funkcjonalnym.
3. Uruchom Sprint 4 (DB) najpierw na środowisku testowym, potem produkcyjnym.
4. Wykonaj Sprint 5 i wymagaj zielonych testów przed merge.
5. Zrób Sprint 6 i formalny raport release readiness.

## 5. Branching i release
1. Branch roboczy: `feature/ccp2-ccp3-unification`.
2. Merge po akceptacji Sprintu 5 i review Sprintu 6.
3. DB migration rollout:
- staging -> walidacja -> produkcja.
4. Rollback:
- zgodnie z runbookiem Sprintu 4.

## 6. Definicja ukończenia (DoD)
1. Wszystkie scenariusze akceptacyjne przechodzą.
2. Brak defektów P0/P1.
3. Raport końcowy GO/NO-GO podpisany.
4. Monitoring po wdrożeniu aktywny min. 48h.

## 7. Lista plików sprintowych
1. `22_Sprint_0_Baseline.md`
2. `22_Sprint_1_Target_Contract.md`
3. `22_Sprint_2_M03_History.md`
4. `22_Sprint_3_M06_CCP3_Monthly.md`
5. `22_Sprint_4_DB_Backfill.md`
6. `22_Sprint_5_Testing.md`
7. `22_Sprint_6_Review_Assessment.md`
