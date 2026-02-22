# Release Checklist (GMP ↔ Supabase)

## A. Przed wdrożeniem
- [ ] Branch release gotowy.
- [ ] Sprint 0-5 zamknięte.
- [x] SQL zweryfikowany na staging.
- [x] Plan rollback zatwierdzony.

## B. Wdrożenie aplikacji
- [ ] Deploy wersji z kompatybilnym odczytem legacy `form_id`.
- [ ] Smoke test formularzy GMP.

## C. Wdrożenie DB
- [ ] Deploy indeksów/constraints.
- [ ] Deploy RLS.
- [x] Migracja danych historycznych.

## D. Walidacja powdrożeniowa
- [x] Historia GMP pokazuje poprawne rekordy.
- [x] CCP-3 filtruje po aktywnej strefie/lokalu.
- [x] Brak wzrostu błędów zapisu.

## E. Obserwacja 48h
- [ ] Monitoring błędów i wydajności.
- [ ] Decyzja o zamknięciu wdrożenia.
