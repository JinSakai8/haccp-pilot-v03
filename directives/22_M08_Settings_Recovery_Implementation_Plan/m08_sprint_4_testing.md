# Sprint 4 — Testing: QA Persona "The Nerd" + E2E Persistence

## 1. Cel sprintu
Zweryfikować end-to-end trwałość danych M08 na ścieżce produkcyjnej.

## 2. Persona QA: "The Nerd" (manual checklist mode)
Charakter pracy:
- rygorystyczna weryfikacja kontraktów danych,
- testy negatywne i graniczne,
- potwierdzenie readback po refresh/relogin.

## 3. Scenariusze E2E (obowiązkowe)
| ID | Scenariusz | Oczekiwany wynik |
|---|---|---|
| E2E-1 | Manager: zmiana `name/address`, save, refresh | Dane utrwalone |
| E2E-2 | Manager: `nip` puste, save | Save przechodzi, `nip=NULL` |
| E2E-3 | Manager: upload logo + save + odczyt logo | `logo_url` utrwalone i renderowalne |
| E2E-4 | Cook: próba zapisu settings | Brak zapisu (RLS deny) |
| E2E-5 | Błędny `nip` | UI blokuje lub DB odrzuca z czytelnym błędem |
| E2E-6 | Awaria uploadu logo (symulacja) | Jasny komunikat, brak fałszywego sukcesu |

## 4. Zestaw testów automatycznych
- Feature tests M08 settings.
- Test integracyjny save->readback.
- SQL smoke `m08_04_settings_smoke_tests.sql` (uzupełnione UUID dla env testowego).

## 5. Raport QA (wymagany)
`S4_qa_report.md`:
1. matrix pass/fail,
2. reprodukcja błędów,
3. logi i screenshoty krytycznych przypadków.

## 6. Definition of Done Sprintu 4
- Wszystkie scenariusze E2E krytyczne: PASS.
- Brak nierozwiązanych blockerów P0/P1.
