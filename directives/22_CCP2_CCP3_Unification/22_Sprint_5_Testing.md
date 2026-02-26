# Sprint 5: Testy Kompleksowe

## Cel sprintu
Potwierdzić formalnie poprawność i brak regresji.

## Zakres testów
1. Unit:
- miesięczny query spec dla CCP3,
- mapowanie okresu (month anchor -> month range),
- cache key `venue+type+generation_date`.
2. Widget:
- GMP Historia: klik CCP2/CCP3 -> właściwy route preview,
- M06: wybór typu i miesiąca dla CCP2/CCP3.
3. Integration:
- generacja -> upload -> metadata save -> reopen z archiwum.
4. SQL contract:
- integralność `generated_reports` (`ccp2_roasting`, `ccp3_cooling`),
- scoping `venue_id` i unikalność.
5. Smoke:
- brak regresji CCP1.

## Komendy testowe
1. `C:\scr\flutter\bin\flutter.bat test --reporter compact`
2. `C:\scr\flutter\bin\flutter.bat test test/features/m03_gmp --reporter compact`
3. `C:\scr\flutter\bin\flutter.bat test test/features/m06_reports --reporter compact`

## Zadania dla juniora
1. Dodać brakujące testy CCP3 monthly.
2. Uaktualnić testy kontraktowe po zmianie semantyki okresu.
3. Zebrać raport PASS/FAIL per scenariusz.

## Exit criteria
1. Wszystkie testy krytyczne zielone.
2. Brak defektów P0/P1.
