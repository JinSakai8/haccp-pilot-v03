# Release Checklist (GMP ↔ Supabase)

## A. Przed wdrożeniem
- [x] Branch release gotowy.
- [ ] Sprint 0-5 zamknięte.
- [x] SQL zweryfikowany na staging.
- [x] Plan rollback zatwierdzony.

## B. Wdrożenie aplikacji
- [ ] Deploy wersji z kompatybilnym odczytem legacy `form_id`.
- [ ] Smoke test formularzy GMP.

## C. Wdrożenie DB
- [x] Deploy indeksów/constraints.
- [x] Deploy RLS.
- [x] Migracja danych historycznych.

## D. Walidacja powdrożeniowa
- [x] Historia GMP pokazuje poprawne rekordy.
- [x] CCP-3 filtruje po aktywnej strefie/lokalu.
- [x] Brak wzrostu błędów zapisu.

## E. Obserwacja 48h
- [ ] Monitoring błędów i wydajności.
- [ ] Decyzja o zamknięciu wdrożenia.

## F. Plan testow (canary + 48h)
- [x] Plan przygotowany: `directives/18_GMP_DB_Implementation_Plan/10_Release_Test_Plan.md`.
- [ ] Uruchomic Etap 2 (Canary rollout).
- [ ] Uruchomic Etap 3 (Obserwacja 48h).
