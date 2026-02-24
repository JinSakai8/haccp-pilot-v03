# Sprint 4: QA, Release, Rollback

Cel sprintu: zamknac technicznie i operacyjnie wdrozenie M08.
Rozmiar sprintu: maly (1 okno kontekstowe).

## 1. Zakres
1. Testy integracyjne i regresyjne dla M08.
2. Testy bezpieczenstwa RLS (venues/products).
3. Runbook wdrozeniowy i rollback.
4. Aktualizacja dokumentacji koncowej (master + changelog).

## 2. Kroki wykonania (dla juniora)
1. Przygotuj liste scenariuszy testowych E2E:
- login -> wybor strefy -> hub -> settings -> save.
- settings/products CRUD.
- dostep rolowy.
2. Uruchom testy automatyczne i dopisz brakujace przypadki.
3. Wykonaj SQL smoke po migracjach na srodowisku staging.
4. Przygotuj checklist release:
- migracje applied,
- RLS verified,
- UI smoke complete,
- rollback ready.
5. Przygotuj rollback:
- odtworzenie poprzednich policy,
- ewentualny rollback kolumn/constraint,
- procedura awaryjna dla niedzialajacego settings.

## 3. Kryteria akceptacji
1. Brak regresji w glownej nawigacji i modulach powiazanych.
2. M08 stabilny przez caly cykl testowy (bez zawieszen i crashy).
3. Potwierdzony rollback testowany na staging.
4. Dokumentacja po wdrozeniu jest aktualna i jednoznaczna.

## 4. Test matrix (minimum)
1. Role: owner/manager/cook/cleaner.
2. Dane: poprawne, brakujace, niepoprawne.
3. Siec: online/offline/intermittent.
4. DB: RLS allow/deny.

## 5. Artefakty sprintu
1. Raport wykonania testow.
2. Release checklist signed-off.
3. Runbook rollback.
4. Aktualizacja pliku master plan.

## 6. Wyjscie sprintu
M08 gotowy do bezpiecznego wdrozenia produkcyjnego.
