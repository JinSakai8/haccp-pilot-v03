# Sprint 4 - UI + History + Preview

## Status Sprintu
- Status: Zakonczony (UI + history + preview wdrozone)
- Data zamkniecia: 2026-02-27
- Decyzja: READY FOR SPRINT 5

## Cel Sprintu
Dostarczyc pelny UX: data wykonania w checklistach, szczegoly historii GHP i podglad raportow z archiwum.

## 1. Zakres UI (wykonany)
- Checklista GHP: pole daty/godziny wykonania.
- Historia GHP: szczegoly wpisu (wartosci, komentarze, wykonawca, czas).
- Reports history: podglad/otwieranie raportu GHP rowniez na mobile.
- Chemicals: zastapienie mock listy zrodlem runtime.

## 2. Wdrozone zmiany
### 2.1 GHP checklist screen
- `lib/features/m04_ghp/screens/ghp_checklist_screen.dart`
  - dodano jawny panel wyboru daty i godziny wykonania,
  - walidacja blokuje submit bez daty/godziny,
  - payload submit zawiera `execution_date`, `execution_time`, `answers`.

### 2.2 GHP chemicals screen
- `lib/features/m04_ghp/screens/ghp_chemicals_screen.dart`
  - usunieto hardcoded mock,
  - lista chemii pobierana z `ChecklistDefinitions.ghpChemicalsCatalog`,
  - dodano date/godzine wykonania i walidacje przed zapisem.

### 2.3 Shared config
- `lib/features/shared/config/checklist_definitions.dart`
  - dodano runtime source: `ghpChemicalsCatalog`.

### 2.4 GHP history screen
- `lib/features/m04_ghp/screens/ghp_history_screen.dart`
  - dodano filtry: kategoria + data,
  - dodano nawigacje do ekranu szczegolow wpisu,
  - szczegoly zawieraja metadane wykonania + wszystkie odpowiedzi (`answers`) + `notes`.

### 2.5 Saved reports screen
- `lib/features/m06_reports/screens/saved_reports_screen.dart`
  - dodano osobne akcje: `PODGLAD` i `POBIERZ`,
  - dodano etykiete typu `ghp_checklist_monthly`,
  - fallback dla uszkodzonego PDF pozostaje (CCP2/CCP3 force preview regenerate).

### 2.6 Mobile file open
- `lib/core/services/file_opener_stub.dart`
  - zastapiono stub realnym flow: zapis bytes do temp + udostepnienie pliku (SharePlus).
- `lib/core/services/pdf_service.dart`
  - `openFile` deleguje do `openFileFromBytes` na wszystkich targetach.

## 3. Krytyczne UX Guardrails (wynik)
- Kiosk-friendly CTA i brak dead-end flow: SPELNIONE.
- Czytelny feedback sukces/blad: SPELNIONE.
- Historia i archiwum maja sciezke wejscia do detalu/otwarcia: SPELNIONE.

## 4. Exit Criteria
- User moze zapisac checklist z data/godzina wykonania: SPELNIONE.
- User moze wejsc w szczegoly wpisu historycznego GHP: SPELNIONE.
- User moze otworzyc raport GHP z archiwum (web + mobile): SPELNIONE.

## 5. Ready for Sprint 5
Sprint 4 zamkniety. Mozna przejsc do Sprint 5 (Testy).
