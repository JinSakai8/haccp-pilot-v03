# Sprint 0: Manual Checklist (CCP2/CCP3)

Data: 2026-02-26
Status: Ready for execution

## A. M03 GMP Historia
1. Otwórz `M03 > Historia GMP`.
2. Kliknij wpis `food_cooling`.
3. Oczekiwane: nawigacja do `/reports/preview/ccp3?date=YYYY-MM-DD`.
4. Kliknij wpis `meat_roasting`.
5. Oczekiwane: nawigacja do `/reports/preview/ccp2?date=YYYY-MM-DD`.
6. Kliknij wpis innego typu (np. `delivery_control`).
7. Oczekiwane: komunikat fallback (brak podgl¹du dedykowanego).

## B. M06 Panel Raportów
1. Otwórz `M06 > Raporty`.
2. Wybierz typ `Druk CCP-2 (Pieczenie)`.
3. Wybierz miesi¹c (nie przysz³y).
4. Oczekiwane: przycisk prowadzi do podgl¹du CCP2 miesiêcznego.
5. Powtórz dla `Druk CCP-3 (Ch³odzenie)`.
6. Oczekiwane: przycisk prowadzi do podgl¹du CCP3 miesiêcznego.

## C. Preview + Cache
1. WejdŸ pierwszy raz w CCP2/CCP3 dla miesi¹ca z danymi.
2. Oczekiwane: wygenerowanie PDF + zapis do storage + wpis w `generated_reports`.
3. WejdŸ drugi raz na ten sam miesi¹c.
4. Oczekiwane: odczyt z cache (`generated_reports` + storage download).

## D. Archiwum M06
1. Otwórz `M06 > Archiwum`.
2. Otwórz raport typu `ccp2_roasting`.
3. Otwórz raport typu `ccp3_cooling`.
4. Oczekiwane: poprawne pobranie i otwarcie PDF.
5. Wymuœ scenariusz uszkodzonego PDF (np. rêczna podmiana pliku).
6. Oczekiwane: fallback do `/reports/preview/ccp2|ccp3?...&force=1` i regeneracja.

## E. Bezpieczeñstwo/tenant
1. Pracownik z `venue A` widzi tylko raporty `venue A`.
2. Brak odczytu raportów `venue B`.
3. Brak cross-tenant fallback, gdy `venue_id` nie jest zgodne.

## F. Kryteria zaliczenia manual
1. 0 b³êdów krytycznych P0/P1.
2. Pe³ny flow CCP2 i CCP3 dzia³a w M03 i M06.
3. Archiwum otwiera oba typy raportów.
4. Potwierdzony brak wycieku cross-tenant.
