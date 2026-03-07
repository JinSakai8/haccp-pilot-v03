# Integration Sprint 4 - Testing

## 1. Cel Sprintu
Weryfikacja E2E przeplywu cross-module i edge case'ow integralnosci danych.

## 2. Scenariusze E2E
### 2.1 M08 -> M04 (Pomieszczenia)
1. Zaloguj jako manager.
2. Wejdz: `Settings -> Zarzadzaj produktami -> Pomieszczenia`.
3. Dodaj nowe pomieszczenie.
4. Wejdz: `GHP -> Pomieszczenia`.
5. Potwierdz widocznosc nowego wpisu w dropdown.

Oczekiwane:
- Dane widoczne w tej samej sesji po refresh/invalidation providera.

### 2.2 M07 -> M04 (Personel)
1. Zaloguj jako manager.
2. Dodaj pracownika w M07.
3. Wejdz do checklisty `GHP -> Personel`.
4. Potwierdz widocznosc nowego pracownika w dropdown.

### 2.3 Edge Case: deaktywacja pracownika
1. Utworz wpis M04 ze wskazanym pracownikiem.
2. Dezaktywuj pracownika w M07.
3. Otworz detal historycznego wpisu M04.

Oczekiwane:
- Detal pokazuje snapshot nazwy z logu.
- Nowy formularz nie oferuje pracownika nieaktywnego.

## 3. RLS i Role Regression
- Cook: brak uprawnien do CRUD `rooms` w M08.
- Manager/Owner: CRUD `rooms` dozwolony w scope lokalu.

## 4. Testy Niefunkcjonalne
- Dropdowny pokazuja stany `loading/error/empty`.
- Brak silent fail przy timeout/offline.
- Komunikaty bledow mapowane do komunikatow domenowych.

## 5. Checklista Test Cases
1. M08 CRUD `rooms` manager.
2. M08 CRUD `rooms` cook denied.
3. M04 Personnel: submit blocked bez pracownika.
4. M04 Rooms: submit blocked bez pomieszczenia.
5. Snapshot `{id,name}` zapisany dla personelu i pomieszczenia.
6. Historia renderuje nazwe ze snapshotu po zmianie referencji.
7. Refresh sesji nie jest wymagany do odswiezenia listy po mutacji.
8. Brak regresji `cooling/roasting/general`.
