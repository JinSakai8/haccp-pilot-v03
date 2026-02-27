# M08 Master Plan: Persistence Failure Recovery (UI -> State -> DB)

## 1. Cel biznesowy
Przywrócić pełną trwałość ustawień lokalu w M08:
- nazwa lokalu (`venues.name`)
- adres lokalu (`venues.address`)
- logo (`venues.logo_url` + Storage `branding`)

## 2. Objaw incydentu
UI sygnalizuje poprawne działanie, ale zmiany użytkownika nie są trwale zapisane lub nie są odczytywane po odświeżeniu.

## 3. Zidentyfikowane ryzyka (audyt)
| ID | Ryzyko | Warstwa | Skutek | Priorytet |
|---|---|---|---|---|
| R1 | `nip=''` zamiast `NULL` łamie check `venues_nip_digits_check` | Frontend payload / DB | Cały `UPDATE venues` odrzucony | Krytyczny |
| R2 | Upload logo tłumi błędy i zwraca `null` | Storage / Repository | Brak trwałości logo bez jasnego błędu | Wysoki |
| R3 | Brak jawnej walidacji/diagnostyki Storage `branding` (policy/bucket) | DB Storage policy | Upload blokowany przez RLS/policy | Wysoki |
| R4 | Brak testu E2E save->readback dla M08 settings | QA | Regresje niewykryte | Wysoki |
| R5 | Niespójność mapowania błędów (DB vs Storage) | UX/Observability | Trudna diagnoza produkcyjna | Średni |

## 4. Spis sprintów
1. `m08_sprint_1_analysis.md` — Audyt i potwierdzenie root cause
2. `m08_sprint_2_backend_db.md` — DB + Storage hardening
3. `m08_sprint_3_frontend_api.md` — Payload + submit flow + walidacje
4. `m08_sprint_4_testing.md` — QA persona „The Nerd”, E2E
5. `m08_sprint_5_evaluation.md` — Ocena wdrożenia i DoD

## 5. Zależności między sprintami
| Sprint | Wymaga zakończenia | Dlaczego |
|---|---|---|
| S2 | S1 | Potwierdzone punkty awarii i kontrakt danych |
| S3 | S2 | Front musi wysyłać payload zgodny z naprawionym kontraktem DB/Storage |
| S4 | S2 + S3 | Testujemy finalną ścieżkę end-to-end |
| S5 | S4 | Ocena na podstawie wyników testów i logów |

## 6. Context Hygiene (modularność)
- Każdy sprint operuje na maks. 6-10 plikach źródłowych.
- Zakaz „load all docs”; tylko pliki wskazane w danym sprincie.
- Każdy sprint kończy się artefaktem 1-stronicowym: findings/changes/risks.

## 7. Kryterium końcowe programu naprawczego
Zmiana `name/address/logo`:
1) zapisuje się bez błędu,
2) jest widoczna po refresh/relogin,
3) nie narusza RLS i constraints,
4) przechodzi checklistę E2E i smoke SQL.
