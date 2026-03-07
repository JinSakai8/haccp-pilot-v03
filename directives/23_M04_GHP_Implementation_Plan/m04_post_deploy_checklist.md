# M04/M06 Post-Deploy Checklist (Manual E2E + Monitoring)

## Cel
Zweryfikowac po wdrozeniu produkcyjnym, ze flow GHP dziala end-to-end:
`submit checklist -> history detail -> report generate -> archive -> open`.

## Zakres i odpowiedzialnosc
- Zakres: M04 GHP + M06 Reports (GHP monthly).
- Owner: release manager / on-duty engineer.
- Data wykonania: w dniu deploy oraz po 24h.

## 1. Pre-check (przed testem manualnym)
1. Potwierdz wersje release (commit/tag).
2. Potwierdz, ze migracja `20260227133000_m04_ghp_generated_reports_report_type.sql` jest na remote.
3. Potwierdz aktywny `kiosk_context` (zalogowany user + wybrana strefa).
4. Potwierdz dostep do bucketu `reports` i tabeli `generated_reports`.

## 2. Manual E2E (must-pass)
1. Login + wybor strefy:
- Oczekiwane: brak bledu auth/context.

2. M04 Checklist:
- Wejdz `/ghp/checklist` (np. `personnel`).
- Uzupelnij odpowiedzi.
- Ustaw `execution_date` i `execution_time`.
- Zapisz.
- Oczekiwane: success feedback, brak bledu walidacji.

3. M04 Chemicals:
- Wejdz `/ghp/chemicals`.
- Wprowadz zuzycie >= 1 pozycji.
- Ustaw `execution_date` i `execution_time`.
- Zapisz.
- Oczekiwane: success feedback, dane zapisane.

4. M04 History:
- Wejdz `/ghp/history`.
- Uzyj filtrow (kategoria + data).
- Otworz detail wpisu.
- Oczekiwane: widoczne `execution_date`, `execution_time`, `answers`, `notes` (jesli podane).

5. M06 Report Generate:
- Wejdz `/reports`.
- Wybierz typ `Checklisty GHP`.
- Wybierz miesiac z danymi.
- Generuj.
- Oczekiwane: PDF wygenerowany, bez krytycznego bledu.

6. M06 Archive:
- Wejdz `/reports/history`.
- Znajdz wpis typu `ghp_checklist_monthly`.
- Uzyj `PODGLAD` lub `POBIERZ`.
- Oczekiwane: otwarcie/udostepnienie PDF.

## 3. Walidacja danych po E2E
1. `haccp_logs`:
- nowe rekordy `category='ghp'` zawieraja `data.execution_date` i `data.execution_time`.

2. `generated_reports`:
- nowy rekord z:
  - `report_type='ghp_checklist_monthly'`
  - `storage_path` zgodnym z `reports/<venueId>/<YYYY>/<MM>/<file>.pdf`
  - `metadata.period_start`, `metadata.period_end`, `metadata.template_version`, `metadata.source_form_id`, `metadata.zone_id`.

3. Storage:
- plik PDF istnieje pod sciezka wskazana w `storage_path`.

## 4. Scenariusze bledne (must-check)
1. Brak pliku/uszkodzony PDF w archiwum:
- Oczekiwane: czytelny komunikat bledu, brak crasha.

2. Brak strefy / brak usera:
- Oczekiwane: walidacyjny komunikat i brak cichej porazki.

3. Brak danych miesiecznych GHP:
- Oczekiwane: komunikat o pustym datasecie.

## 5. Monitoring 24h po deploy
1. Bledy klienta (UI/provider):
- monitoruj wzrost bledow dla `/ghp/*` i `/reports/*`.

2. Storage/reporting:
- monitoruj nieudane uploady do bucketu `reports`.
- monitoruj nieudane upserty `generated_reports`.

3. KPI operacyjne:
- liczba zapisow GHP/dzien,
- liczba wygenerowanych raportow GHP,
- liczba nieudanych otwarc PDF.

## 6. Kryteria akceptacji post-deploy
- Wszystkie kroki Manual E2E: PASS.
- Brak P1 incydentow przez 24h.
- Brak niespojnosci `storage_path` vs plik bucket.
- Brak regresji CCP1/CCP2/CCP3 zgloszonej przez operatorow.

## 7. Escalation
- P1 (NO-GO/hotfix): brak mozliwosci archiwizacji raportu lub crash przy otwieraniu.
- P2 (hotfix planowany): sporadyczne bledy UI bez utraty danych.
- P3 (backlog): usprawnienia UX bez ryzyka zgodnosci danych.
