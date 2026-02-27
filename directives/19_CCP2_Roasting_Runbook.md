# CCP2 Roasting Runbook (2026-02-26)

## Scope

Runbook obejmuje wdrozenie i operacje dla:

- M03 formularz `meat_roasting` (CCP2 payload),
- M06 raport `ccp2_roasting` (PDF + cache + archiwum),
- kontrakty DB/Storage (`haccp_logs`, `generated_reports`, `reports` bucket).

## Deployment order

1. Zastosuj migracje Supabase:
   - `20260226160000_ccp2_roasting_report_type.sql`
   - `20260226173000_ccp2_generated_reports_hardening.sql`
2. Zweryfikuj polityki i indeksy:
   - uruchom `36_validate_ccp2_contract.sql`.
3. Wydaj aplikacje z nowym buildem Flutter.

## Post-deploy verification

1. W M03 zapisz wpis pieczenia z `is_compliant=true`.
2. W M03 zapisz wpis pieczenia z `is_compliant=false` i `corrective_actions`.
3. W M06 wygeneruj CCP2 dla miesiaca:
   - sprawdz, ze zawiera wpisy z calego miesiaca,
   - sprawdz storage path `reports/{venueId}/{YYYY}/{MM}/ccp2_roasting_{YYYY-MM}.pdf`,
   - sprawdz wpis w `generated_reports` (`report_type=ccp2_roasting`).
4. Wejdz ponownie w ten sam miesiac i potwierdz cache hit.
5. Sprawdz archiwum raportow (otwarcie poprawnego pliku).

## Rollback

1. App rollback:
   - cofnij do poprzedniego artefaktu aplikacji.
2. DB rollback (tylko jesli wymagane):
   - usun nowe polityki `generated_reports_*_kiosk_scope`,
   - przywroc poprzednie polityki permissive dla `generated_reports`,
   - usun index unikalny `generated_reports_unique_venue_type_date` jesli powoduje konflikt z legacy flow.
3. Dla incydentu danych:
   - odtworz wpisy metadanych z backupu DB.

## Incident checklist

1. Brak raportu CCP2:
   - sprawdz `haccp_logs` dla `form_id='meat_roasting'` i zakres miesiaca.
2. Brak dostepu do raportu:
   - sprawdz `kiosk_sessions` i dopasowanie `venue_id`.
3. Brak zapisu metadanych:
   - sprawdz constrainty `generated_reports` i uprawnienia RLS.
4. Niepoprawny PDF:
   - porownaj payload row map i fallbacki (`is_compliant`, `corrective_actions`).
