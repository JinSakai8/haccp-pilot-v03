# Supabase Contract (Sprint 6 Refresh)

Data aktualizacji: 2026-02-20  
Status: Zgodne ze stanem kodu aplikacji

---

## 1. Punkt dostepu do Supabase

Jedyny punkt dostepu do klienta:

- `lib/core/services/supabase_service.dart`

Udostepniane interfejsy:

- `SupabaseService.client`
- `SupabaseService.storage`
- `SupabaseService.auth`
- `SupabaseService.realtime`

Podczas inicjalizacji aplikacja probuje wykonac `signInAnonymously()` jesli nie ma sesji.

---

## 2. Tabele uzywane w kodzie

Ponizej lista tabel i widokow wykorzystywanych przez repozytoria/provider-y.

### `employees`

- Uzycie:
  - `hr_repository.dart` (`updatePin`)
  - `dashboard_badges_provider.dart` (liczniki HR)
- Przykladowe pola w modelach: `id`, `full_name`, `role`, `is_active`, `sanepid_expiry`.

### `public_employees` (widok)

- Uzycie:
  - `hr_repository.dart` (`getEmployees`)
- Cel: odczyt listy pracownikow dla panelu HR.

### `employee_zones`

- Uzycie:
  - `auth_repository.dart` (`getZonesForEmployee`)
- Relacja pracownik <-> strefy.

### `zones`

- Uzycie:
  - `hr_repository.dart` (`getZones`)
- Metadane stref.

### `venues`

- Uzycie:
  - `venue_repository.dart` (`getSettings`, `updateSettings`)
  - `reports_repository.dart` (`getVenueLogo`)
- Ustawienia lokalu i branding.

### `products`

- Uzycie:
  - `products_repository.dart` (`getProducts`, `addProduct`, `updateProduct`, `deleteProduct`)
- Logika: wspiera produkty globalne (`venue_id is null`) i lokalne (`venue_id = ...`).

### `haccp_logs`

- Uzycie:
  - `gmp_repository.dart` (`category = gmp`)
  - `ghp_repository.dart` (`category = ghp`)
  - `reports_repository.dart` (raporty GMP/CCP3)
  - `dashboard_badges_provider.dart` (liczniki)
- Typowe pola zapisu: `category`, `form_id`, `data`, `user_id`, `zone_id`, `venue_id`, `created_at`.

### `waste_records`

- Uzycie:
  - `waste_repository.dart`
  - `reports_repository.dart`
  - `dashboard_badges_provider.dart`
- Typowe pola zapisu: `venue_id`, `zone_id`, `user_id`, `waste_type`, `waste_code`, `mass_kg`, `recipient_company`, `kpo_number`, `photo_url`.

### `sensors`

- Uzycie:
  - `measurements_repository.dart` (`getSensors`)
- Filtrowanie m.in. po `zone_id`, `is_active`.

### `temperature_logs`

- Uzycie:
  - `measurements_repository.dart` (stream, historia, alerty, acknowledge)
  - `reports_repository.dart` (agregacje raportowe)
- Typowe pola: `sensor_id`, `temperature_celsius`, `recorded_at`, `is_alert`, `is_acknowledged`, `acknowledged_by`, `acknowledged_at`.

### `annotations`

- Uzycie:
  - `measurements_repository.dart` (`insertAnnotation`)
- Adnotacje do wykresow czujnikow.

### `generated_reports`

- Uzycie:
  - `reports_repository.dart` (`saveReportMetadata`, `getSavedReport`, `getGeneratedReports`)
- Typowe pola: `venue_id`, `report_type`, `generation_date`, `created_by`, `storage_path`, `metadata`.

---

## 3. Funkcje RPC wykorzystywane przez aplikacje

- `login_with_pin(pin_input)` - logowanie PIN.
- `check_pin_availability(pin_input)` - walidacja unikalnosci PIN.
- `create_employee(name_input, pin_hash_input, role_input, sanepid_input, zone_ids_input, is_active_input)` - tworzenie pracownika.
- `update_employee_sanepid(employee_id, new_expiry)` - aktualizacja badan.
- `toggle_employee_active(employee_id, new_status)` - aktywacja/dezaktywacja.

---

## 4. Supabase Storage (buckety)

### `waste-docs`

- Zdjecia dokumentacji odpadow.
- Uzycie: `storage_service.dart`, `pdf_service.dart` (odczyt obrazow).

### `reports`

- Wygenerowane raporty PDF.
- Uzycie: `reports_repository.dart` (upload/download).

### `branding`

- Loga lokali.
- Uzycie: `venue_repository.dart` (upload logo), `reports_repository.dart` (pobranie logo do PDF).

---

## 5. RLS i dostep

Kod zaklada:

1. Dostep anonimowy po inicjalizacji (anon session), zgodnie z politykami projektu.
2. Ograniczenia danych per lokal realizowane przez RLS oraz filtracje po `venue_id`/`zone_id`.
3. Operacje uprzywilejowane (HR, logowanie PIN) sa przeniesione do RPC.

---

## 6. Ryzyka kontraktowe do monitorowania

1. Widok `public_employees` musi byc utrzymany zgodnie z modelem `Employee`.
2. Funkcje RPC musza utrzymywac aktualna sygnature zgodna z repozytoriami.
3. Tabela `temperature_logs` musi zawierac `temperature_celsius` (mapowanie w modelu).
4. Tabela `annotations` musi byc dostepna dla insert z aplikacji.
