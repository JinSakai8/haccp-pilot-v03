# CCP2 Sprint 4: Operability Runbook

## Scope
Runbook dla strumienia `ccp2_roasting`:
- odczyt logow (`haccp_logs`),
- generacja PDF,
- zapis metadata (`generated_reports`),
- odzyskiwanie z historii.

## 1) Szybka diagnostyka (app)
1. Uruchom aplikacje z flaga debug raportow:
   - `--dart-define=HACCP_REPORTS_DEBUG=true`
2. Wygeneruj CCP2 z panelu raportow.
3. Sprawdz logi:
   - `getRoastingLogs spec` (zoneId/venueId/formIds/range),
   - `getRoastingLogs raw counts`,
   - `getRoastingLogs final count`,
   - `getSavedReport result` (hit/miss),
   - `downloadReport bytes`.

## 2) SQL diagnostyczny (DB)
Uzyj zapytan z pliku:
- `directives/19_CCP2_Roasting_Sprint_4_DB_Verification.sql`

Najwazniejsze kontrole:
- czy wpisy sa pod `form_id in ('meat_roasting','meat_roasting_daily')`,
- czy rekordy maja poprawne `venue_id`/`zone_id`,
- czy jest wpis w `generated_reports` dla `report_type='ccp2_roasting'`,
- czy `storage_path` wskazuje na bucket `reports`.

## 3) Regeneracja raportu (bez cache)
1. Wejdz do archiwum raportow.
2. Kliknij raport CCP2.
3. Gdy plik jest uszkodzony, ekran automatycznie przekierowuje do:
   - `/reports/preview/ccp2?date=YYYY-MM-DD&force=1`
4. To pomija cache i wymusza nowa generacje + zapis nowego pliku.

## 4) Naprawa metadata (generated_reports)
Przypadki naprawcze:
- brak `period_start`/`period_end`,
- niepoprawny `source_form_id`,
- niepoprawny `storage_path`.

Dzialanie:
1. Odszukaj rekord po `venue_id + report_type + generation_date`.
2. Popraw `metadata` i/lub `storage_path`.
3. Zweryfikuj odczyt z historii.

## 5) Rollback operacyjny
1. Problemy tylko z pojedynczym miesiacem:
   - usun rekord `generated_reports` dla tego miesiaca,
   - wygeneruj ponownie CCP2 (autoodtworzenie).
2. Problemy po wdrozeniu SQL:
   - rollback ostatniej migracji (zgodnie z procedura projektu),
   - przywroc backup danych jesli migracja modyfikowala rekordy.

## 6) Kryteria GO/NO-GO (Sprint 4)
GO gdy:
- CCP2 generuje PDF dla danych canonical + legacy,
- historia otwiera PDF lub skutecznie wymusza regeneracje,
- brak odczytu/zapisu poza scope venue/zone,
- telemetry pozwala odtworzyc przyczyne bledu bez debuggera.

NO-GO gdy:
- final count w query > 0, a PDF nadal sie nie generuje,
- zapis metadata nie przechodzi mimo poprawnego kiosk context,
- odczyt historii zwraca rekord innego venue.
