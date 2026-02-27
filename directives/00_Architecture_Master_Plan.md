# 00 - Architecture Master Plan (Source of Truth)
## Kiedy Dolaczac Ten Plik Do Konwersacji
- Gdy ustalasz kierunek architektury i scope prac.
- Gdy potrzebujesz mapy zaleznosci miedzy modulami.
- Gdy analizujesz ryzyka, trade-offy i niefunkcjonalne wymagania.
- Gdy chcesz zweryfikowac routing na poziomie architektury.
- Nie dolaczaj do pytan o szczegoly SQL lub pixel-level UI.

## 1. Cel i Zakres Architektury
Ten dokument jest glownym Source of Truth dla architektury HACCP Pilot.

Zakres:
- Big picture systemu i granice domen.
- Zaleznosci miedzy modulami i warstwami.
- Decyzje architektoniczne i trade-offy.
- Niefunkcjonalne wymagania.

Poza zakresem:
- Szczegoly implementacji kodu, sygnatury metod, szczegoly testow.
- SQL DDL/DML, szczegoly polityk RLS i definicje RPC.
- Szczegolowe layouty UI i stany ekranow.

## 2. Kontekst Systemu i Bounded Contexts
Aplikacja jest systemem kioskowym opartym o Flutter + Supabase. Konteksty biznesowe:

| Kontekst | Moduly | Odpowiedzialnosc |
|:--|:--|:--|
| Access & Session | M01 + core auth | PIN login, kontekst kiosku (uzytkownik/strefa), guardy roli |
| Monitoring | M02 | Odczyty temperatur, alarmy, adnotacje, edycja ograniczona regułami |
| HACCP Operations | M03 + M04 + M05 | GMP, GHP, odpady, rejestracje operacyjne |
| Reporting | M06 | Generacja preview/PDF, archiwum raportow |
| Workforce | M07 | Kadry, statusy pracownikow, zarzadzanie PIN i danymi personelu |
| Venue Configuration | M08 | Ustawienia lokalu, branding, produkty |
| Shared Platform | shared + core | Routing, providers, komponenty wspolne, uslugi techniczne |

## 3. Warstwy i Przeplywy Miedzy Warstwami
Model warstwowy (feature-first, clean-lite):

1. Presentation
2. State
3. Data Access
4. Infra

Przeplyw standardowy:
- `Screen/Widget -> Provider/Notifier -> Repository -> SupabaseService -> Supabase`

Reguly:
- Brak bezposrednich wywolan Supabase z warstwy ekranow.
- Feature boundaries: modul ma wlasne repo/provider/screen, a cross-cutting trafia do `core` albo `shared`.
- Error propagation: mapowanie bledow na poziomie repository/provider, nie w komponentach niskopoziomowych UI.

## 4. Mapa Modulow i Zaleznosci Miedzy Modulami
Stabilne zaleznosci:

- `core` jest zaleznoscia dla wszystkich modulow.
- `shared` dostarcza silnik dynamicznych formularzy i wspolne repozytoria/definicje.
- `dashboard` agreguje badge i nawiguje do M02-M08.
- M06 konsumuje dane operacyjne z M02/M03/M05 do raportowania.
- M06 konsumuje rowniez dane M04 (`haccp_logs`, `category=ghp`) do miesiecznego raportu GHP i archiwizacji.
- M08 dostarcza konfiguracje runtime (branding/produkty/parametry lokalu) wykorzystywana przez inne moduly.
- M04 konsumuje dane referencyjne cross-module: pracownicy z M07 oraz slownik pomieszczen z M08.

Zaleznosci, ktorych unikamy:
- Bezposrednie wywolania miedzy ekranami modulow.
- Kopiowanie logiki domenowej miedzy modulami zamiast reuse przez shared/core.

## 5. Globalne Decyzje Architektoniczne (Zamrozone)
1. Feature-first jako glowna organizacja kodu.
2. Riverpod jako jednolity model stanu.
3. GoRouter jako centralny routing i guard layer.
4. Multi-tenant scope przez kontekst kiosku + RLS po stronie danych.
5. Kiosk UX constraints: glove-friendly, minimal keyboard usage, czytelne stany krytyczne.
6. Archiwizacja raportow: storage + metadata table jako kontrakt trwalosci.

## 6. Mapa Routingu na Poziomie Architektury
Routing podzielony domenowo:

- Access:
  - `/`, `/login`, `/zone-select`
- Hub:
  - `/hub`
- Monitoring:
  - `/monitoring`, `/monitoring/alarms`, `/monitoring/chart/:deviceId`
- GMP:
  - `/gmp`, `/gmp/roasting`, `/gmp/cooling`, `/gmp/delivery`, `/gmp/history`
- GHP:
  - `/ghp`, `/ghp/checklist`, `/ghp/history`, `/ghp/chemicals`
- Waste:
  - `/waste`, `/waste/register`, `/waste/camera`, `/waste/history`
- Reports:
  - `/reports`, `/reports/preview/local`, `/reports/preview/ccp2`, `/reports/preview/ccp3`, `/reports/history`, `/reports/drive`
- HR:
  - `/hr`, `/hr/list`, `/hr/add`, `/hr/employee/:id`
- Settings:
  - `/settings`, `/settings/products`

Guardy architektoniczne:
- Niezalogowany nie wchodzi do tras aplikacyjnych.
- Uzytkownik zalogowany nie wraca na trasy logowania.
- Trasy HR/Settings tylko dla manager/owner.

## 7. Niefunkcjonalne Wymagania
Security:
- Tenant isolation i role-based access.
- Brak przechowywania surowych PIN po stronie klienta.
- Krytyczne akcje domenowe przez kontrolowane kontrakty backendowe.

Offline/Resilience:
- Czytelny stan offline i degradacja funkcji zaleznych od sieci.
- Brak ukrytego fallbacku maskujacego bledy krytyczne.

Performance:
- Selektywne odswiezanie stanu (Riverpod granularity).
- Query scoping i indeksowanie po stronie danych.
- Ograniczanie kosztu renderu dla ekranow listowych/raportowych.

Maintainability:
- Jednoznaczny podzial odpowiedzialnosci dokumentow i kodu.
- Kontrakty miedzy warstwami utrzymywane przez testy.

## 8. Ryzyka i Trade-offs
| Obszar | Ryzyko | Trade-off | Mitigacja |
|:--|:--|:--|:--|
| Sessionless kiosk auth | Rozjazd sesji i scope danych | Prostszy flow logowania vs wyzsza wrazliwosc na konfiguracje auth | Guardrails na poziomie RPC + RLS + runbook incydentowy |
| Dynamic forms | Roznica miedzy definicja a implementacja raportow | Szybkosc rozwoju vs zlozonosc kontraktow | Versioning definicji i testy kontraktowe |
| Reporting persistence | Rozjazd storage i metadata | Elastycznosc archiwizacji vs koniecznosc spojnosc i rollback | Upsert contract + walidacje post-migration |
| Scope dokumentacji | Dryf miedzy warstwami | Wysoka szczegolowosc vs czytelnosc i modularnosc | Scope lint i ownership per plik |

## 9. Do Weryfikacji / Legacy
Sekcja celowo zachowuje dane o niepewnym statusie. Nie sa one usuwane, dopoki nie zostana potwierdzone.

1. Dawne nazwy encji/tabel uzywane historycznie w dokumentacji:
- `profiles` vs `employees`
- `measurements/devices` vs `temperature_logs/sensors`

2. Historyczne zalozenia architektoniczne do potwierdzenia:
- Wczesniejszy opis nested navigation przez `ShellRoute` (obecnie routing jest flat i jawny).
- Starsze opisy komponentow/plikow, np. `settings_repository.dart` (aktualnie `venue_repository.dart`).

3. Historyczne dane sprintowe i wyniki testow:
- Szczegolowe logi wdrozen i wyniki `xx passed` zostaly celowo usuniete z glownej narracji.
- W razie potrzeby audytu nalezy je czerpac z historii git, runbookow i artefaktow `directives/`.

4. Legacy kontrakty raportowe/form_id:
- Obsluga wpisow legacy typu `meat_roasting_daily` w nawigacji i raportowaniu pozostaje w kodzie.
- Docelowa decyzja o pelnej deprecjacji wymaga osobnego ticketu migracyjnego.

## 10. Zweryfikowany Snapshot Implementacyjny (2026-02-27)
Poniższy snapshot został zweryfikowany względem aktualnego stanu repo i jest kanoniczny na dzień 2026-02-27.

### 10.1 Struktura `lib/` (aktualna)
```text
lib/
├── main.dart
├── core/
│   ├── config/env_config.dart
│   ├── constants/design_tokens.dart
│   ├── models/{employee.dart,zone.dart}
│   ├── providers/{auth_provider.dart,connectivity_provider.dart}
│   ├── repositories/auth_repository.dart
│   ├── router/{app_router.dart,route_names.dart}
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── pdf_service.dart
│   │   ├── drive_service.dart
│   │   ├── storage_service.dart
│   │   ├── connectivity_service.dart
│   │   └── file_opener_{web,stub}.dart (+ file_opener.dart)
│   ├── theme/app_theme.dart
│   └── widgets/
│       ├── haccp_top_bar.dart
│       ├── haccp_stepper.dart
│       ├── haccp_tile.dart
│       ├── haccp_long_press_button.dart
│       ├── haccp_time_picker.dart
│       ├── haccp_date_picker.dart
│       ├── haccp_num_pad.dart
│       ├── success_overlay.dart
│       ├── empty_state_widget.dart
│       └── offline_banner.dart
├── features/
│   ├── dashboard/
│   │   ├── screens/dashboard_hub_screen.dart
│   │   └── providers/dashboard_badges_provider.dart
│   ├── m01_auth/screens/{splash_screen.dart,pin_pad_screen.dart,zone_selection_screen.dart}
│   ├── m02_monitoring/
│   │   ├── screens/{temperature_dashboard_screen.dart,sensor_chart_screen.dart,alarms_panel_screen.dart}
│   │   ├── repositories/measurements_repository.dart
│   │   ├── models/{sensor.dart,temperature_log.dart,alarm_list_item.dart}
│   │   └── providers/monitoring_provider.dart
│   ├── m03_gmp/
│   │   ├── screens/{gmp_process_selector_screen.dart,meat_roasting_form_screen.dart,food_cooling_form_screen.dart,delivery_control_form_screen.dart,gmp_history_screen.dart}
│   │   ├── repositories/gmp_repository.dart
│   │   ├── providers/gmp_provider.dart
│   │   └── config/gmp_form_ids.dart
│   ├── m04_ghp/
│   │   ├── screens/{ghp_category_selector_screen.dart,ghp_checklist_screen.dart,ghp_chemicals_screen.dart,ghp_history_screen.dart}
│   │   ├── repositories/ghp_repository.dart
│   │   └── providers/ghp_provider.dart
│   ├── m05_waste/
│   │   ├── screens/{waste_panel_screen.dart,waste_registration_form_screen.dart,haccp_camera_screen.dart,waste_history_screen.dart}
│   │   ├── repositories/waste_repository.dart
│   │   └── models/waste_record.dart
│   ├── m06_reports/
│   │   ├── screens/{reports_panel_screen.dart,pdf_preview_screen.dart,ccp2_preview_screen.dart,ccp3_preview_screen.dart,saved_reports_screen.dart,drive_status_screen.dart}
│   │   ├── repositories/reports_repository.dart
│   │   ├── providers/reports_provider.dart
│   │   ├── models/daily_temperature_stats.dart
│   │   └── services/{html_report_generator.dart,temperature_aggregator_service.dart}
│   ├── m07_hr/
│   │   ├── screens/{hr_dashboard_screen.dart,employee_profile_screen.dart,add_employee_screen.dart,employee_list_screen.dart}
│   │   ├── repositories/hr_repository.dart
│   │   ├── providers/hr_provider.dart
│   │   └── utils/hr_alerts_snapshot.dart
│   ├── m08_settings/
│   │   ├── screens/{global_settings_screen.dart,manage_products_screen.dart}
│   │   ├── repositories/venue_repository.dart
│   │   └── providers/m08_providers.dart
│   └── shared/
│       ├── config/{form_definitions.dart,checklist_definitions.dart}
│       ├── models/form_definition.dart
│       ├── providers/dynamic_form_provider.dart
│       ├── repositories/products_repository.dart
│       └── widgets/dynamic_form/*
└── .env
```

### 10.2 Mapa Routingu (aktualna: 32 trasy)
```text
/                           -> SplashScreen
/login                      -> PinPadScreen
/zone-select                -> ZoneSelectionScreen
/hub                        -> DashboardHubScreen

/monitoring                 -> TemperatureDashboardScreen
/monitoring/alarms          -> AlarmsPanelScreen
/monitoring/chart/:deviceId -> SensorChartScreen

/gmp                        -> GmpProcessSelectorScreen
/gmp/roasting               -> MeatRoastingFormScreen
/gmp/cooling                -> FoodCoolingFormScreen
/gmp/delivery               -> DeliveryControlFormScreen
/gmp/history                -> GmpHistoryScreen

/ghp                        -> GhpCategorySelectorScreen
/ghp/checklist              -> GhpChecklistScreen
/ghp/history                -> GhpHistoryScreen
/ghp/chemicals              -> GhpChemicalsScreen

/waste                      -> WastePanelScreen
/waste/register             -> WasteRegistrationFormScreen
/waste/camera               -> HaccpCameraScreen
/waste/history              -> WasteHistoryScreen

/settings                   -> GlobalSettingsScreen
/settings/products          -> ManageProductsScreen

/reports                    -> ReportsPanelScreen
/reports/preview/local      -> PdfPreviewScreen
/reports/preview/ccp3       -> Ccp3PreviewScreen
/reports/preview/ccp2       -> Ccp2PreviewScreen
/reports/history            -> SavedReportsScreen
/reports/drive              -> DriveStatusScreen

/hr                         -> HrDashboardScreen
/hr/list                    -> EmployeeListScreen
/hr/add                     -> AddEmployeeScreen
/hr/employee/:id            -> EmployeeProfileScreen
```

### 10.3 Architektura Warstwowa (clean-lite)
```text
UI (Screens/Widgets)
  -> State (Riverpod Notifier/Provider)
    -> Data (Repositories)
      -> Infra (SupabaseService / external services)
```

### 10.4 Repository Contract (aktualny)
| Modul | Repository | Glowny kontrakt danych |
|:--|:--|:--|
| M01 | `AuthRepository` | `employees`, `employee_zones`, `zones` + RPC auth/session |
| M02 | `MeasurementsRepository` | `sensors`, `temperature_logs`, `annotations` + RPC alarm/edit/ack |
| M03 | `GmpRepository` | `haccp_logs` (`category=gmp`) |
| M04 | `GhpRepository` | `haccp_logs` (`category=ghp`, z polami wykonania w `data`) |
| M05 | `WasteRepository` | `waste_records` |
| M06 | `ReportsRepository` | `generated_reports`, `haccp_logs`, `temperature_logs`, `venues`, storage (w tym `ghp_checklist_monthly`) |
| M07 | `HrRepository` | RPC HR + `public_employees`, `zones` |
| M08 | `VenueRepository` + `ProductsRepository` | `venues`, `products`, branding storage |

### 10.5 Kluczowe zaleznosci (pubspec.yaml, aktualne)
```yaml
dependencies:
  flutter_riverpod: ^3.2.1
  riverpod_annotation: ^4.0.2
  go_router: ^17.1.0
  supabase_flutter: ^2.12.0
  flutter_dotenv: ^6.0.0
  google_fonts: ^8.0.1
  connectivity_plus: ^7.0.0
  crypto: ^3.0.7
  fl_chart: ^1.1.1
  syncfusion_flutter_pdfviewer: ^32.2.4
  syncfusion_flutter_pdf: ^32.2.4
  camera: ^0.11.3+1
  image: ^4.7.2
  riverpod_generator: ^4.0.3 # dev
  build_runner: ^2.11.1      # dev
```

