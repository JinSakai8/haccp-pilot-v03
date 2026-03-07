# Sprint 1: Stabilizacja wejscia do M08

Cel sprintu: usunac nieskonczone ladowanie `m08_settings` i ustabilizowac kontrakt wejscia na ekran.
Rozmiar sprintu: maly (1 okno kontekstowe).

## 1. Zakres
1. Naprawic zrodlo `venueId` w M08:
- primary source: `currentZoneProvider.venueId`.
- fallback: jawny blad stanu, nie loader bez konca.
2. Wprowadzic jawne stany ekranu:
- `loading`,
- `error` (z komunikatem i CTA),
- `ready`.
3. Dodac bezpieczna obsluge bledow inicjalizacji:
- brak usera,
- brak strefy,
- wyjatek z repozytorium.
4. Ujednolicic pobieranie repozytorium przez provider (bez recznego `AuthRepository()`).

## 2. Kroki wykonania (dla juniora)
1. Zidentyfikuj wszystkie miejsca, gdzie M08 samodzielnie odczytuje strefy do wyznaczenia `venueId`.
2. Zastap ten mechanizm odczytem aktualnej strefy z globalnego stanu.
3. Dodaj komponent ekranu bledu z jasnym komunikatem i akcjami:
- "Wroc do Hub",
- "Sprobuj ponownie".
4. Upewnij sie, ze `build()` nie ma warunku, ktory moze utkwić na stale.
5. Dodaj log diagnostyczny (debug) dla kluczowych przejsc stanu.

## 3. Kryteria akceptacji
1. Brak nieskonczonego loadera w zadnym scenariuszu.
2. Przy braku strefy widoczny jest blad i mozliwosc powrotu.
3. Przy poprawnym kontekście ustawienia laduja sie od razu.
4. Brak nieobsluzonych wyjatkow w init flow M08.

## 4. Testy
1. Manual: manager z poprawnym zone -> ekran gotowy.
2. Manual: cook (ukryty kafelek + direct URL) -> brak dostepu po wdrozeniu sprintu 2; na sprint 1 co najmniej brak zawieszenia.
3. Manual: symulowany blad sieci -> blad ekranowy zamiast spinnera.
4. Widget test: render stanu `error` i `ready`.

## 5. Ryzyka
1. Zaleznosc od poprawnego ustawienia `currentZoneProvider` po logowaniu.
2. Mozliwa regresja w innych modulach korzystajacych z tego samego kontekstu.

## 6. Wyjscie sprintu
1. Stabilny flow wejscia do `/settings`.
2. Zdiagnozowany i usuniety incydent "wieczne ladowanie".
3. Gotowosc do sprintu 2 (kontrakt danych i DB).
