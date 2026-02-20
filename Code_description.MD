# Code Description: HACCP Pilot (Sprint 6 Refresh)

Data aktualizacji: 2026-02-20  
Status: Zgodne ze stanem kodu po Sprintach 1-5

---

## 0. Srodowisko lokalne

- Lokalna sciezka Flutter SDK: `C:\scr\flutter\bin`
- Preferowane komendy:
  - `C:\scr\flutter\bin\flutter.bat analyze`
  - `C:\scr\flutter\bin\flutter.bat test`

---

## 1. Architektura aplikacji

Projekt ma uklad Feature-First z centralnym rdzeniem `core`.

- `core`: routing, serwisy, modele globalne, motyw, wspolne widgety.
- `features`: moduly domenowe `m01`-`m08` + `dashboard` + `shared`.

Docelowy przeplyw warstw:

`Screen -> Provider -> Repository -> SupabaseService -> Supabase`

Zasady architektoniczne:

1. Jeden punkt dostepu do klienta Supabase: `lib/core/services/supabase_service.dart`.
2. Brak bezposrednich zapytan DB/Storage w UI.
3. Logika danych tylko w `repositories/` i serwisach.
4. Routing oparty o stale z `lib/core/router/route_names.dart`.

---

## 2. Struktura kodu (skrot)

Kluczowe katalogi:

- `lib/core/config`
- `lib/core/constants`
- `lib/core/models`
- `lib/core/providers`
- `lib/core/repositories`
- `lib/core/router`
- `lib/core/services`
- `lib/core/theme`
- `lib/core/widgets`
- `lib/features/dashboard`
- `lib/features/m01_auth` ... `lib/features/m08_settings`
- `lib/features/shared` (definicje formularzy, renderer, repo produktow)

---

## 3. Routing i autoryzacja

Pliki:

- `lib/core/router/route_names.dart`
- `lib/core/router/app_router.dart`

Guardy:

1. Niezalogowany uzytkownik jest przekierowany na `RouteNames.login`.
2. Zalogowany na trasach auth (`/`, `/login`) jest przekierowany na `RouteNames.hub`.
3. Trasy `RouteNames.hr*` i `RouteNames.settings*` sa ograniczone do `employee.isManager`.

---

## 4. Moduly i odpowiedzialnosci

### M01 Auth

- Ekrany: `splash_screen.dart`, `pin_pad_screen.dart`, `zone_selection_screen.dart`
- Repo: `lib/core/repositories/auth_repository.dart`
- Logowanie: RPC `login_with_pin` + pobranie stref z `employee_zones`.

### Dashboard

- Ekran: `dashboard_hub_screen.dart`
- Badge provider: `dashboard_badges_provider.dart` (agregacje z tabel domenowych).

### M02 Monitoring

- Repo: `measurements_repository.dart`
- Tabele: `sensors`, `temperature_logs`, `annotations`
- Funkcje: lista sensorow, realtime stream pomiarow, historia, alerty, adnotacje.

### M03 GMP

- Repo: `gmp_repository.dart`
- Tabela: `haccp_logs` (`category = gmp`)
- Formy: pieczenie, chlodzenie, kontrola dostaw + historia.

### M04 GHP

- Repo: `ghp_repository.dart`
- Tabela: `haccp_logs` (`category = ghp`)
- Checklisty + historia.

### M05 Waste

- Repo: `waste_repository.dart`
- Tabela: `waste_records`
- Kamera: `haccp_camera_screen.dart`
- Upload plikow: `storage_service.dart` do bucketu `waste-docs`.

### M06 Reports

- Repo: `reports_repository.dart`
- Tabele: `haccp_logs`, `temperature_logs`, `waste_records`, `generated_reports`, `venues`
- Storage: `reports`, `branding`
- Serwisy: `pdf_service.dart`, `html_report_generator.dart`, `temperature_aggregator_service.dart`.

### M07 HR

- Repo: `hr_repository.dart`
- Widok/tabele: `public_employees`, `employees`, `zones`
- RPC: `check_pin_availability`, `create_employee`, `update_employee_sanepid`, `toggle_employee_active`.

### M08 Settings

- Repo: `venue_repository.dart` + `products_repository.dart`
- Tabele: `venues`, `products`
- Bucket: `branding` (logo lokalu).

---

## 5. Serwisy core

- `supabase_service.dart`: inicjalizacja klienta + anon session fallback.
- `storage_service.dart`: upload do Supabase Storage.
- `pdf_service.dart`: generowanie dokumentow PDF.
- `drive_service.dart`: warstwa integracji Google Drive.
- `app_logger.dart`: ustandaryzowane logowanie (`debug`, `warning`, `error`).
- `connectivity_service.dart`: status polaczenia.

---

## 6. UI i komponenty wspolne

- Canonical widgety sa w `lib/core/widgets`.
- Dynamic forms korzystaja z `lib/features/shared/widgets/dynamic_form/dynamic_form_renderer.dart`.
- Po Sprint 2 usunieto duplikaty widgetow z `features/shared/widgets/dynamic_form`.

---

## 7. Jakosc i status

- Sprint 1: hardening data layer - completed.
- Sprint 2: konsolidacja widgetow - completed.
- Sprint 3: routing i lifecycle alignment - completed.
- Sprint 4: naprawa testow - completed.
- Sprint 5: production hardening (logging/cleanup) - completed.
- Sprint 6: dokumentacja - completed.

---

## 8. Powiazane dokumenty

- `directives/00_Architecture_Master_Plan.md`
- `supabase.md`
- `UI_description.md`
