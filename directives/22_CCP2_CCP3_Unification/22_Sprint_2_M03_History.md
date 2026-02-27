# Sprint 2: M03 GMP Historia (Nawigacja + UX)

Data: 2026-02-26  
Status: COMPLETED

## Cel sprintu
Zapewniæ, ¿e z historii GMP otwieraj¹ siê poprawne podgl¹dy raportów dla CCP2 i CCP3.

## Zakres
1. Dodaæ obs³ugê klikniêcia CCP2 w historii.
2. Ujednoliciæ semantykê daty dla CCP3 do modelu miesiêcznego.
3. Usun¹æ placeholdery typu „wkrótce” dla CCP2.
4. Ujednoliciæ komunikaty b³êdów i fallbacki.

## Zmiany techniczne
1. `gmp_history_screen.dart`:
- rozpoznanie `form_id` po normalizacji,
- route push dla CCP2 i CCP3.
2. `gmp_form_ids.dart`:
- spójne etykiety procesów.

## Zadania dla juniora
1. Wdro¿ routing i warunki `onTap` per typ formularza.
2. Zachowaj kompatybilnoœæ z legacy `form_id`.
3. Dodaj smoke test nawigacji.

## Exit criteria
1. CCP2 i CCP3 otwieraj¹ preview z GMP Historii.
2. Brak regresji dla innych procesów GMP.

## Implementacja (wykonana)
1. `gmp_history_screen.dart`:
- nawigacja zosta³a ujednolicona przez wspólny resolver trasy,
- routing dzia³a dla CCP2 i CCP3,
- komunikat fallback zosta³ ujednolicony.
2. `gmp_form_ids.dart`:
- dodano `gmpHistoryPreviewRoute(...)` (mapowanie `form_id -> route`),
- zachowana kompatybilnoœæ legacy przez `normalizeGmpFormId(...)`,
- dodano wspóln¹ sta³¹ komunikatu fallback.
3. Testy:
- dodany smoke test nawigacji:
  - `test/features/m03_gmp/gmp_history_navigation_smoke_test.dart`.

## Wynik walidacji
1. `C:\scr\flutter\bin\flutter.bat test test/features/m03_gmp --reporter compact`
- PASS (`12 passed, 0 failed`).
