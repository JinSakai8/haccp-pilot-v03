# Plan Implementacji GMP ↔ Supabase (Index)

Ten dokument jest podzielony na mniejsze pliki, aby zmniejszyć zużycie tokenów na pojedynczą rozmowę.

## Jak pracować (token-friendly)
- Otwieraj tylko jeden plik sprintowy na sesję.
- Dla zmian DB używaj osobno runbooka SQL.
- Do statusu wdrożenia używaj checklisty release.

## Podział plików
1. `directives/18_GMP_DB_Implementation_Plan/01_Context_And_Priorities.md`
2. `directives/18_GMP_DB_Implementation_Plan/02_Sprint_0_1.md`
3. `directives/18_GMP_DB_Implementation_Plan/03_Sprint_2_3.md`
4. `directives/18_GMP_DB_Implementation_Plan/04_Sprint_4_5.md`
5. `directives/18_GMP_DB_Implementation_Plan/05_DB_Runbook_RLS_Migration.md`
6. `directives/18_GMP_DB_Implementation_Plan/06_Release_Checklist.md`
7. `directives/18_GMP_DB_Implementation_Plan/10_Release_Test_Plan.md`

## Rekomendowana kolejność rozmów
1. Kontekst i priorytety.
2. Sprint 0-1 (kontrakt danych + quick wins).
3. Sprint 2-3 (CCP-3 + hardening DB).
4. Sprint 4-5 (migracja danych + release).
5. Runbook DB i checklista produkcyjna.
6. Plan testow release (canary + 48h).
