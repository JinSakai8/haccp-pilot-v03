# Release Test Plan (na bazie `06_Release_Checklist.md`)

## Cel
Domknac otwarte punkty checklisty release i przygotowac decyzje go-live.

## Etap 1: Pre-release gate (Dzien 0)

### 1.1 Branch i artefakty
- Potwierdz branch release i commit SHA.
- Potwierdz, ze migracje remote sa zsynchronizowane:
  - `supabase migration list --linked`
- Potwierdz, ze plan rollback jest aktualny:
  - DB rollback: `haccp_logs_sprint4_backup_20260222`
  - rollback plikow/wersji aplikacji przez Git/Vercel redeploy.

### 1.2 Smoke po deploy aplikacji
- Scenariusz A: logowanie PIN -> wybor strefy -> zapis `food_cooling`.
- Scenariusz B: zapis `meat_roasting` i `delivery_control`.
- Oczekiwane:
  - brak bledow zapisu,
  - rekordy widoczne w historii GMP.

## Etap 2: Canary rollout (Dzien 0-1)

### 2.1 Zakres canary
- 1 lokal testowy (lub ograniczona grupa uzytkownikow).
- Czas trwania: min. 24h aktywnego uzycia.

### 2.2 Testy funkcjonalne (manual E2E)
- E2E-1: `food_cooling` -> podglad CCP-3 -> generacja PDF.
- E2E-2: `meat_roasting` -> historia GMP (rekord widoczny i poprawny `form_id`).
- E2E-3: `delivery_control` -> historia GMP (rekord widoczny i poprawny `form_id`).
- E2E-4: separacja stref:
  - ta sama data, 2 strefy, sprawdz brak przecieku danych miedzy strefami.
- E2E-5: separacja lokali:
  - brak odczytu danych cross-venue.

### 2.3 Testy operacyjne
- Odczyt metryk bledow aplikacji (Sentry/Crashlytics/logi serwera).
- Kontrola wydajnosci kluczowych zapytan (CCP-3, historia GMP).

## Etap 3: Obserwacja 48h (Dzien 1-3)

### 3.1 Monitoring
- Co 12h raport:
  - liczba bledow krytycznych,
  - liczba nieudanych zapisow GMP,
  - zgłoszenia od uzytkownikow.

### 3.2 Kryteria przejscia
- 0 bledow krytycznych.
- Brak wzrostu bledow zapisu vs baseline.
- Potwierdzenie biznesowe: historia GMP i CCP-3 dzialaja poprawnie.

## Etap 4: Decyzja go-live close

### 4.1 GO
- Zamknij checklisty:
  - `06_Release_Checklist.md` sekcja E.
- Oznacz release jako stabilny.

### 4.2 NO-GO / rollback
- DB: przywroc dane z `haccp_logs_sprint4_backup_20260222` (jesli dotyczy).
- App: rollback deploymentu na Vercel do poprzedniego SHA.
- Powtorz canary po poprawkach.
