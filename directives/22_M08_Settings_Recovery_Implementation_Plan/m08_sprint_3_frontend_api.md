# Sprint 3 — Frontend/API: Submit Flow and Payload Validation

## 1. Cel sprintu
Domknąć klienta M08 tak, aby wysyłał poprawny payload i nie ukrywał awarii persistence.

## 2. Zakres
- Normalizacja payload przed wysyłką (`nip`, `name`, `address`, `logo_url`).
- Poprawa submit flow i mapowania błędów.
- Wyraźne komunikaty dla awarii uploadu logo i awarii DB update.

## 3. Zadania wykonawcze
1. Wprowadzić regułę: puste `nip` -> `NULL` w payload (nie `''`).
2. Oddzielić błędy:
- logo upload fail,
- update venues fail.
3. Zapewnić readback po zapisie (odświeżenie stanu providera).
4. Dodać walidację payloadu przed submit:
- `name` non-empty,
- `address` non-empty,
- `nip` = 10 cyfr albo puste.
5. Zapewnić brak silent fallback dla logo (jeśli upload nie przeszedł, użytkownik dostaje klarowny komunikat i decyzję retry/cancel).

## 4. Interfejsy publiczne do aktualizacji
| Komponent | Zmiana |
|---|---|
| `VenueRepository.updateSettings` | semantyka `nip nullable` |
| `VenueSettingsController.updateSettings` | kontrakt wejściowy zgodny z DB |
| `GlobalSettingsScreen` submit | jawna sekwencja: validate -> upload -> update -> readback |

## 5. Testy frontend/API
1. Widget/Integration: `nip` puste -> zapis przechodzi.
2. Widget/Integration: `nip` niepoprawne -> blokada przed wysyłką.
3. Integration: upload logo fail -> komunikat + brak fałszywego sukcesu.
4. Integration: save success -> po reload wartości są identyczne.

## 6. Definition of Done Sprintu 3
- Frontend nie wysyła payloadów łamiących kontrakt DB.
- Użytkownik zawsze wie, czy fail dotyczy Storage czy DB.
- Save/readback działa deterministycznie.
