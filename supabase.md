# Dokumentacja Bazy Danych (Supabase)

Dokument opisuje aktualny stan bazy danych projektu HACCP Pilot, relacje między tabelami oraz powiązania z modułami aplikacji. Stan na: **Luty 2026**.

> **Źródła:**
>
> - [Code_description.MD](Code_description.MD) (Opis architektury)
> - Pliki migracyjne SQL (`*_create_*.sql`, `*_update_*.sql`)

---

## 1. Schemat Relacyjny (ERD)

```mermaid
erDiagram
    VENUES ||--o{ EMPLOYEES : "zatrudnia"
    VENUES ||--o{ ZONES : "posiada"
    VENUES ||--o{ PRODUCTS : "menu lokalne"
    VENUES ||--o{ WASTE_RECORDS : "generuje"
    VENUES ||--o{ GENERATED_REPORTS : "archiwizuje"
    
    EMPLOYEES ||--o{ EMPLOYEE_ZONES : "przypisany"
    ZONES ||--o{ EMPLOYEE_ZONES : "dostępna dla"
    
    ZONES ||--o{ SENSORS : "monitoruje"
    SENSORS ||--o{ TEMPERATURE_LOGS : "mierzy"
    
    products ||--o{ HACCP_LOGS : "używany w (JSONB)"
    
    VENUES {
        uuid id PK
        string name
        string nip
        string address
        string logo_url
        int temp_interval
        float temp_threshold
    }

    EMPLOYEES {
        uuid id PK
        uuid venue_id FK
        string full_name
        string pin_hash
        string role "owner/manager/cook"
        date sanepid_expiry
    }

    products {
        uuid id PK
        uuid venue_id FK "nullable (null=global)"
        string name
        string type "cooling/roasting/general"
        timestamp created_at
    }

    HACCP_LOGS {
        uuid id PK
        uuid venue_id FK
        string form_id
        string category "gmp/ghp"
        jsonb data
        uuid created_by
    }

    GENERATED_REPORTS {
        uuid id PK
        uuid venue_id FK
        string report_type
        date generation_date
        string storage_path
        jsonb metadata
    }
```

---

## 2. Szczegółowy Opis Tabel

### 2.1 Konfiguracja i Struktura (`venues`, `zones`, `employees`)

| Tabela | Kolumna | Typ | Opis |
|:---|:---|:---|:---|
| **`venues`** | `id` | UUID (PK) | Unikalny identyfikator lokalu. |
| | `name` | TEXT | Nazwa lokalu (np. "Restauracja U Jana"). |
| | `nip` | TEXT | Numer NIP. |
| | `logo_url` | TEXT | URL do logo w Storage (`branding`). |
| | `temp_interval` | INT | Częstotliwość pomiarów IoT (minuty). |
| **`employees`** | `id` | UUID (PK) | ID pracownika. |
| | `venue_id` | UUID (FK) | Powiązanie z lokalem. |
| | `pin_hash` | TEXT | Hash SHA-256 kodu PIN (4 cyfry). |
| | `role` | TEXT | Rola: `owner`, `manager` lub `cook`. |
| **`zones`** | `id` | UUID (PK) | ID strefy (np. Kuchnia, Magazyn). |
| | `venue_id` | UUID (FK) | Powiązanie z lokalem. |

### 2.2 Produkty i Procesy (`products`, `haccp_logs`)

| Tabela | Kolumna | Typ | Opis |
| :--- | :--- | :--- | :--- |
| **`products`** | `id` | UUID (PK) | ID produktu. |
| | `venue_id` | UUID (FK) | Jeśli `NULL` -> Produkt Globalny (widoczny wszędzie). Jeśli podane -> Produkt Lokalny (tylko dla tego `venue`). |
| | `name` | TEXT | Nazwa potrawy/produktu. Unikalna w obrębie lokalu (`UNIQUE NULLS NOT DISTINCT (name, venue_id)`). |
| | `type` | TEXT | Typ: `cooling`, `roasting`, `general`. |
| **`haccp_logs`** | `id` | UUID (PK) | ID wpisu loga. |
| | `venue_id` | UUID (FK) | Powiązanie z lokalem (kluczowe do filtracji danych i RLS). |
| | `zone_id` | UUID (FK) | Powiązanie ze strefą (np. Kuchnia). |
| | `category` | TEXT | `gmp` (formularze) lub `ghp` (checklisty). |
| | `form_id` | TEXT | ID formularza, np. `food_cooling`. |
| | `data` | JSONB | Pełne dane wpisu (dynamiczna struktura formularza). |
| | `user_id` | UUID (FK) | ID pracownika (`employees`), który wykonał czynność. |
| | `created_by` | UUID (FK) | ID użytkownika Supabase Auth (techniczne). |

### 2.3 Monitoring IoT (`sensors`, `temperature_logs`)

| Tabela | Kolumna | Typ | Opis |
|:---|:---|:---|:---|
| **`sensors`** | `id` | UUID (PK) | ID czujnika. |
| | `mac_address` | TEXT | Adres fizyczny urządzenia BLE. |
| | `zone_id` | UUID (FK) | Strefa, w której znajduje się czujnik. |
| **`temperature_logs`** | `temperature` | FLOAT | Odczyt temperatury. |
| | `recorded_at` | TIMESTAMPTZ | Czas pomiaru. |

### 2.4 Raporty i Archiwizacja (`generated_reports`)

| Tabela | Kolumna | Typ | Opis |
|:---|:---|:---|:---|
| **`generated_reports`** | `storage_path` | TEXT | Ścieżka do pliku PDF w buckecie `reports`. |
| | `report_type` | TEXT | Typ raportu, np. `ccp3_cooling`. |
| | `generation_date` | DATE | Data, której dotyczy raport. |

---

## 3. Relacje i Powiązania Modułów

Tabela przedstawia, które moduły (M01-M08) korzystają z których tabel (CRUD).

| Moduł | Główna Tabela | Tabele Pomocnicze | Uprawnienia (Zazwyczaj) |
|:---|:---|:---|:---|
| **M01 Auth** | `employees` | `zones`, `employee_zones` | Read (RPC `login_with_pin`) |
| **M02 IoT** | `temperature_logs` | `sensors`, `zones` | Read (Realtime Subscription) |
| **M03 GMP** | `haccp_logs` | `products` | Insert (Log), Read (History, List Products) |
| **M04 GHP** | `haccp_logs` | - | Insert (Log), Read (History) |
| **M05 Waste** | `waste_records` | - | Insert, Read |
| **M06 Reports** | `generated_reports` | `haccp_logs` (source), `temperature_logs` (source) | Read, Insert (PDF generation) |
| **M07 HR** | `employees` | `employee_zones` | CRUD (Manager Only) |
| **M08 Settings** | `venues` | `products`, `sensors` | Update (Venue), CRUD (Products) |

---

1. **Polityki Bezpieczeństwa (RLS)**

Bezpieczeństwo opiera się na Row Level Security. Aplikacja nie korzysta ze standardowego logowania Supabase Auth (email/pass), lecz z własnego mechanizmu opartego na PIN.

1. **Uwierzytelnianie:**
    - Użytkownik podaje PIN (4 cyfry).
    - Aplikacja woła funkcję RPC `login_with_pin(venue_nip, pin)`.
    - Funkcja zwraca token JWT (z `role: authenticated`) oraz dane pracownika.
    - **Ważne**: Tabela `employees` jest chroniona (SELECT tylko dla `authenticated`).

2. **Izolacja Danych (Multi-tenancy):**
    - Większość tabel (`products`, `haccp_logs`, `generated_reports`) posiada kolumnę `venue_id`.
    - Docelowa polityka: `USING (venue_id = (select venue_id from employees where id = auth.uid()))`.
    - **Faza Pilot (Aktualnie)**:
        - `haccp_logs`: `USING (true)` / `CHECK (true)` (Uproszczone dla testów, filtracja w aplikacji).
        - `products`: `USING (true)` (Odczyt globalny).

3. **Role:**
    - Kolumna `role` w `employees` (`owner`, `manager`, `cook`) steruje dostępem do ekranów w aplikacji (Guardy).

---

## 5. Uwagi do Plików Źródłowych

Analiza plików źródłowych wykazała zgodność, z małymi wyjątkami:

- **`Code_description.MD`**: Jest najbardziej aktualny (Luty 2026).
- **`00_Architecture_Master_Plan.md`**: Opisuje plan z 15.02.2026. Struktura jest poprawna, ale szczegóły tabeli `products` (kolumna `venue_id` do multi-tenancy) zostały doprecyzowane w sprincie 5 (SQL `32_update_products_table.sql`). Dokumentacja `supabase.md` uwzględnia ten nowszy stan.

---

## 6. Aktualizacja po Sprint 0-1 (2026-02-22)

Niniejsza sekcja doprecyzowuje najnowszy stan po pracach Sprint 0/1.

### 6.1 Stan schematu i tabel

- Kanoniczna tabela dla logow GMP/GHP: `haccp_logs`.
- W zdalnym `public` nadal istnieja legacy tabele `gmp_logs` oraz `ghp_logs`, ale aktualnie sa puste (0 rekordow).
- Nie wykonano fizycznej migracji danych `form_id` w DB w Sprint 0/1 (to zakres pozniejszych sprintow).

### 6.2 Zamrozony kontrakt `form_id` (GMP)

Docelowe wartosci:

- `food_cooling`
- `meat_roasting`
- `delivery_control`

Kompatybilnosc legacy w odczycie historii:

- `meat_roasting_daily` -> `meat_roasting`
- `delivery_control_daily` -> `delivery_control`

### 6.3 Snapshot diagnostyczny `haccp_logs` (2026-02-22)

- Laczna liczba rekordow: **9**
- Per `form_id`:
  - `food_cooling`: **9**
- `zone_id IS NULL`: **0**
- `venue_id IS NULL`: **0**

### 6.4 RLS

- `haccp_logs` pozostaje w trybie pilotowym RLS (`USING (true)` / `CHECK (true)`).
- Hardening RLS jest zaplanowany na kolejne sprinty (`03_Sprint_2_3.md`).

### 6.5 Artefakty baseline

- `baseline_schema.sql`
- `baseline_haccp_logs_report.md`
- zrodlo baseline schema: `supabase db pull` (plik: `supabase/migrations/20260222084803_remote_schema.sql`)

---

## 7. Aktualizacja po Sprint 2-3 (2026-02-22)

### 7.1 CCP-3 (aplikacja)

- Odczyt logow chlodzenia (`food_cooling`) zostal uszczelniony po kontekscie:
  - priorytet: `zone_id`,
  - fallback: `venue_id` gdy brak `zone_id`.
- Implementacja:
  - `lib/features/m06_reports/repositories/reports_repository.dart`
  - `lib/features/m06_reports/screens/ccp3_preview_screen.dart`

### 7.2 Kontekst kiosk pod RLS (aplikacja)

- Po wyborze strefy aplikacja zapisuje kontekst sesji kiosk przez RPC:
  - `set_kiosk_context(employee_id_input, zone_id_input)`.
- Przy wyjsciu do ekranu logowania aplikacja czysci kontekst:
  - `clear_kiosk_context()`.
- Implementacja:
  - `lib/core/repositories/auth_repository.dart`
  - `lib/features/m01_auth/screens/zone_selection_screen.dart`

### 7.3 Hardening DB (Sprint 3) - przygotowany artefakt SQL

- Dodana migracja:
  - `supabase/migrations/20260222123000_sprint3_haccp_logs_hardening.sql`
- Zakres migracji:
  - tabela `kiosk_sessions` (mapowanie `auth.uid()` -> `employee_id`/`venue_id`/`zone_id`),
  - RPC: `set_kiosk_context`, `clear_kiosk_context`,
  - indeksy `haccp_logs`:
    - `(category, form_id, created_at)`,
    - `(zone_id, created_at)`,
    - `(venue_id, created_at)`,
  - constraints:
    - `category in ('gmp','ghp')`,
    - slownik `form_id` dla GMP/GHP,
  - nowe polityki RLS SELECT/INSERT scoped do `kiosk_sessions`,
  - usuniecie pilotowych polityk `USING/CHECK (true)` dla `haccp_logs`.

### 7.4 Status wdrozenia DB

- Migracja Sprint 3 zostala wdrozona na remote przez `supabase db push` (2026-02-22).
- Stan zdalny zawiera:
  - tabele `kiosk_sessions`,
  - RPC `set_kiosk_context` oraz `clear_kiosk_context`,
  - nowe indeksy i polityki RLS dla `haccp_logs`.

### 7.5 Walidacja testowa po zmianach

- Testy CCP-3/GMP i smoke testy UI przechodza.
- Pelny `flutter test` przechodzi (1 test oznaczony jako `skip` z powodu ograniczenia fontow Syncfusion w runnerze testowym).

---

## 8. Aktualizacja po Sprint 4 (2026-02-22)

### 8.1 Migracja danych historycznych (`haccp_logs`)

- Wdrozona migracja:
  - `supabase/migrations/20260222150000_sprint4_haccp_logs_data_migration.sql`
- Zakres:
  - normalizacja legacy `form_id`:
    - `meat_roasting_daily` -> `meat_roasting`
    - `delivery_control_daily` -> `delivery_control`
  - uzupelnienie brakujacego `venue_id` z mapowania `user_id -> employees.venue_id`,
  - uzupelnienie brakujacego `zone_id` tylko dla jednoznacznych przypisan pracownika do jednej strefy.

### 8.2 Backup i rollback

- Migracja tworzy backup rekordow:
  - `public.haccp_logs_sprint4_backup_20260222`
- Rollback danych jest mozliwy przez odtworzenie `form_id`/`venue_id`/`zone_id` z tabeli backup.

### 8.3 Wynik wykonania na danych produkcyjnych

- `supabase db push` wykonany poprawnie (po 2 poprawkach kompatybilnosci SQL).
- Snapshot po wdrozeniu:
  - `haccp_logs`: 9 rekordow,
  - `food_cooling`: 9,
  - legacy `form_id`: 0,
  - `venue_id IS NULL`: 0,
  - `zone_id IS NULL`: 0.
- Tabela backup istnieje i zawiera 0 rekordow (migracja byla logicznie no-op dla aktualnego zbioru).

---

## 9. Aktualizacja po Sprint 5 (2026-02-22)

### 9.1 Testy automatyczne

- Uruchomiono:
  - `test/db_consistency_test.dart`,
  - `test/features/m03_gmp/gmp_form_id_contract_test.dart`,
  - `test/features/m06_reports/reports_repository_filters_test.dart`,
  - pelny `flutter test`.
- Wynik pelnego suite:
  - 19 passed, 1 skipped, 0 failed.

### 9.2 Status release

- Technicznie:
  - migracje DB (Sprint 3+4) sa wdrozone na remote,
  - testy regresji przechodza.
- Operacyjnie (otwarte):
  - canary rollout,
  - obserwacja 48h i decyzja go-live close.

---

## 10. Krytyczny warunek runtime (Auth)

- Dla modelu kiosk + RLS wymagane jest wlaczenie w Supabase:
  - `Authentication -> Providers -> Anonymous Sign-Ins`.
- Gdy provider jest wylaczony:
  - aplikacja nie moze utworzyc sesji,
  - RPC zalezne od `auth.uid()` (np. `set_kiosk_context`) nie dzialaja.
- Runbook incydentowy:
  - `directives/18_GMP_DB_Implementation_Plan/11_Incident_Recovery_Anonymous_Auth.md`.

---

## 11. Aktualizacja po M06 Sprint 1 (2026-02-22)

### 11.1 `generated_reports.report_type` (CCP-1 temperatura)

- Wdrozona migracja:
  - `supabase/migrations/20260222130356_m06_ccp1_generated_reports_report_type.sql`
- Zmiana:
  - rozszerzenie check constraint `generated_reports_report_type_check`
  - nowy dozwolony typ: `ccp1_temperature`

### 11.2 RLS i zakres zmiany

- RLS dla `generated_reports` bez zmian (tylko check constraint).

### 11.3 Walidacja

- Test pozytywny: insert `report_type='ccp1_temperature'` przechodzi.
- Test negatywny: insert nieznanego typu jest blokowany przez check constraint.
- Test regresji: stare typy (`ccp3_cooling`, `waste_monthly`, `gmp_daily`) nadal przechodza.

---

## 12. Aktualizacja po M06 Sprint 4-5 (2026-02-22)

### 12.1 Finalny zakres zmian DB dla M06 CCP-1

- Jedyna zmiana schematu DB dla M06 CCP-1:
  - rozszerzenie `generated_reports_report_type_check` o `ccp1_temperature`
  - migracja: `supabase/migrations/20260222130356_m06_ccp1_generated_reports_report_type.sql`
- Brak nowych tabel i brak nowych kolumn.
- Brak zmian polityk RLS (dla M06 CCP-1).

### 12.2 Kontrakt archiwizacji w runtime (storage + generated_reports)

- Bucket: `reports`
- Tabela: `generated_reports`
- `report_type`: `ccp1_temperature`
- `storage_path`:
  - `reports/{venueId}/{YYYY}/{MM}/ccp1_temperature_{sensorId}_{YYYY-MM}.pdf`
- `metadata`:
  - `sensor_id`
  - `sensor_name`
  - `month`
  - `template_version = ccp1_csv_v1`

### 12.3 Walidacja koncowa

- Pelny `flutter test` po wdrozeniu M06 CCP-1:
  - **31 passed, 1 skipped, 0 failed**
- Potwierdzone:
  - brak regresji dla pozostalych typow raportow,
  - poprawna archiwizacja `ccp1_temperature` w `generated_reports`,
  - rollback DB nadal oparty o przywrocenie poprzedniego check constraint.
