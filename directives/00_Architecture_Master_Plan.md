# 00 — Architecture Master Plan: HACCP Pilot v03-00

> **Autor:** Lead System Architect (AI)
> **Data:** 2026-02-15
> **Status:** ACTIVE — Po wdrożeniu M06 (Raporty)
> **Deadline:** 2 tygodnie (do 2026-02-27)
> **Źródła:** [Code_description.MD](file:///c:/Users/HP/OneDrive - flowsforge.com/Projekty/HACCP Mięso i Piana/Up to date/Code_description.MD), [UI_description.md](file:///c:/Users/HP/OneDrive - flowsforge.com/Projekty/HACCP Mięso i Piana/Up to date/UI_description.md)

---

## 1. Decyzja Architektoniczna: Struktura Katalogów `lib/`

Stosujemy **Feature-First Architecture** z wyodrębnionym rdzeniem (`core/`). Każdy moduł M01–M09 jest autonomiczną domeną. Warstwa `core/` zawiera współdzieloną logikę, serwisy, widgety i konfigurację.

```
lib/
├── main.dart                          # Entry point, Supabase.initialize()
├── app.dart                           # MaterialApp.router, theme, GoRouter
│
├── core/
│   ├── config/
│   │   └── env_config.dart            # Wrapper na flutter_dotenv
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 theme, Glove-Friendly tokens
│   ├── constants/
│   │   └── design_tokens.dart         # Kolory, rozmiary, paddingi
│   ├── services/
│   │   └── supabase_service.dart      # Singleton accessor do Supabase.instance.client
│   ├── repositories/
│   │   └── auth_repository.dart       # loginWithPin() — Directive 02
│   ├── models/
│   │   ├── employee.dart              # Employee (z tabeli employees)
│   │   └── zone.dart                  # Zone (z tabeli zones)
│   ├── providers/
│   │   ├── auth_provider.dart         # Riverpod: stan zalogowanego usera + zona
│   │   └── connectivity_provider.dart # Riverpod: stan sieci (online/offline)
│   ├── router/
│   │   ├── app_router.dart            # GoRouter config — centralny plik routingu
│   │   └── route_names.dart           # Stałe nazwowe dla ścieżek
│   └── widgets/                       # Moduł M09 — współdzielone komponenty
│       ├── haccp_top_bar.dart
│       ├── haccp_stepper.dart
│       ├── haccp_toggle.dart
│       ├── haccp_tile.dart
│       ├── haccp_long_press_button.dart
│       ├── haccp_time_picker.dart
│       ├── haccp_date_picker.dart
│       ├── haccp_num_pad.dart
│       ├── success_overlay.dart       # Ekran 9.1
│       ├── empty_state_widget.dart    # Ekran 9.2
│       └── offline_banner.dart        # Ekran 9.3
│
├── features/
│   ├── m01_auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart          # Ekran 1.1
│   │   │   ├── pin_pad_screen.dart         # Ekran 1.2
│   │   │   └── zone_selection_screen.dart  # Ekran 1.3
│   │   └── providers/
│   │       └── pin_pad_provider.dart       # Lokalny stan PIN Pad
│   │
│   ├── dashboard/
│   │   └── screens/
│   │       └── dashboard_hub_screen.dart   # Dashboard Hub
│   │
│   ├── m02_monitoring/
│   │   ├── screens/
│   │   │   ├── temperature_dashboard_screen.dart  # Ekran 2.1
│   │   │   ├── sensor_chart_screen.dart            # Ekran 2.2
│   │   │   └── alarms_panel_screen.dart            # Ekran 2.3
│   │   ├── repositories/
│   │   │   └── measurements_repository.dart
│   │   ├── models/
│   │   │   └── measurement.dart
│   │   └── providers/
│   │       └── monitoring_provider.dart
│   │
│   ├── m03_gmp/
│   │   ├── screens/
│   │   │   ├── gmp_process_selector_screen.dart    # Ekran 3.1
│   │   │   ├── meat_roasting_form_screen.dart      # Ekran 3.2
│   │   │   ├── food_cooling_form_screen.dart       # Ekran 3.3
│   │   │   ├── delivery_control_form_screen.dart   # Ekran 3.4
│   │   │   └── gmp_history_screen.dart             # Ekran 3.5
│   │   ├── repositories/
│   │   │   └── gmp_repository.dart
│   │   ├── models/
│   │   │   └── gmp_log.dart
│   │   └── providers/
│   │       └── gmp_provider.dart
│   │
│   ├── m04_ghp/
│   │   ├── screens/
│   │   │   ├── ghp_category_selector_screen.dart       # Ekran 4.1
│   │   │   ├── ghp_personnel_checklist_screen.dart     # Ekran 4.2
│   │   │   ├── ghp_rooms_checklist_screen.dart         # Ekran 4.3
│   │   │   ├── ghp_maintenance_checklist_screen.dart   # Ekran 4.4
│   │   │   ├── ghp_chemicals_registry_screen.dart      # Ekran 4.5
│   │   │   └── ghp_history_screen.dart                 # Ekran 4.6
│   │   ├── repositories/
│   │   │   └── ghp_repository.dart
│   │   ├── models/
│   │   │   └── ghp_log.dart
│   │   └── providers/
│   │       └── ghp_provider.dart
│   │
│   ├── m05_waste/
│   │   ├── screens/
│   │   │   ├── waste_panel_screen.dart                 # Ekran 5.1
│   │   │   ├── waste_registration_form_screen.dart     # Ekran 5.2
│   │   │   ├── waste_camera_screen.dart                # Ekran 5.3
│   │   │   └── waste_history_screen.dart               # Ekran 5.4
│   │   ├── repositories/
│   │   │   └── waste_repository.dart
│   │   ├── models/
│   │   │   └── waste_record.dart
│   │   └── providers/
│   │       └── waste_provider.dart
│   │
│   ├── m06_reports/
│   │   ├── screens/
│   │   │   ├── reports_panel_screen.dart    # Ekran 6.1
│   │   │   ├── pdf_preview_screen.dart     # Ekran 6.2
│   │   │   └── drive_status_screen.dart    # Ekran 6.3
│   │   ├── repositories/
│   │   │   └── reports_repository.dart
│   │   └── providers/
│   │       └── reports_provider.dart
│   │
│   ├── m07_hr/                     # [COMPLETED] Zarządzanie personelem
│   │   ├── screens/
│   │   │   ├── hr_dashboard_screen.dart        # Panel główny z alertami
│   │   │   ├── employee_profile_screen.dart    # Edycja profilu + Sanepid
│   │   │   ├── add_employee_screen.dart        # Dodawanie + Przypisywanie Stref
│   │   │   └── employee_list_screen.dart       # Lista pracowników
│   │   ├── repositories/
│   │   │   └── hr_repository.dart              # Secure RPCs (Auth & Anon)
│   │   ├── models/
│   │   │   └── employee.dart
│   │   └── providers/
│   │       └── hr_provider.dart
│   │
│   └── m08_settings/
│       ├── screens/
│       │   └── global_settings_screen.dart     # Ekran 8.1
│       ├── repositories/
│       │   └── settings_repository.dart
│       └── providers/
│           └── settings_provider.dart
│
└── .env                               # SUPABASE_URL, SUPABASE_ANON_KEY
```

### Uzasadnienie

| Decyzja | Dlaczego |
|:--------|:---------|
| Feature-First (nie Layer-First) | 9 modułów × 1–6 ekranów = 33 ekrany. Przy Layer-First (screens/, repositories/) pliki z różnych domen mieszałyby się. Feature-First zapewnia izolację — usunięcie M05 to usunięcie jednego folderu. |
| `core/widgets/` dla M09 | Ekrany 9.1–9.3 to komponenty wielokrotnego użytku (overlay, widget), nie osobne strony. Trafiają do `core/`, bo korzysta z nich każdy moduł. |
| `core/repositories/` tylko dla auth | Auth jest cross-cutting concern. Reszta repozytoriów żyje w swoich feature'ach, bo nie są współdzielone. |

---

## 2. Decyzja: State Management → **Riverpod** (flutter_riverpod + riverpod_annotation)

### Analiza porównawcza

| Kryterium | Provider | Riverpod | **Werdykt** |
|:----------|:---------|:---------|:------------|
| Dependency Injection bez BuildContext | ❌ Wymaga kontekstu | ✅ Ref-based, testowalne | **Riverpod** |
| Kiosk Mode (globalny stan usera) | Wymaga ProxyProvider/ChangeNotifier | `StateNotifierProvider` z auto-dispose | **Riverpod** |
| Supabase Realtime (M02 streaming) | Trudna integracja ze StreamProvider | Natywny `StreamProvider` | **Riverpod** |
| Compile-time safety | ❌ Runtime exceptions przy brakującym Provider | ✅ Compile-time z `riverpod_generator` | **Riverpod** |
| Wiele modułów w izolacji | Ryzyko Provider Scope pollution | ProviderScope per feature, autodispose | **Riverpod** |
| Krzywa nauki zespołu | Prosta | Umiarkowana | Provider |
| Granularność — odświeżanie widgetów | Nasłuchuje cały ChangeNotifier | `ref.watch()` per provider, selektywne rebuildy | **Riverpod** |

### Werdykt: **Riverpod wygrał 6:1**

Kluczowe powody dla HACCP Pilot:

1. **Kiosk Mode** wymaga globalnego stanu `currentEmployee` i `currentZone` — Riverpod pozwala na `StateProvider` dostępny z każdego ekranu bez propagacji przez drzewo widgetów.
2. **Supabase Realtime** (monitoring M02) to streamy — Riverpod ma natywny `StreamProvider`, który auto-disposuje subskrypcje przy opuszczeniu ekranu.
3. **Role-based access** (M07/M08 tylko dla manager/owner) — `ref.watch(authProvider)` w `GoRouter redirect` daje czystą implementację guardów.

### Pakiety do zainstalowania

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

dev_dependencies:
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.14
```

### Architektura Providerów

```
┌─────────────────────────────────────────────────────┐
│                  ProviderScope                       │
│  (main.dart — opakowuje całą aplikację)              │
│                                                     │
│  ┌───────────────────────────────────────┐           │
│  │  CORE PROVIDERS (globalny cykl życia) │           │
│  │  • authProvider → Employee?           │           │
│  │  • currentZoneProvider → Zone?        │           │
│  │  • connectivityProvider → bool        │           │
│  └───────────────────────────────────────┘           │
│                                                     │
│  ┌───────────────────────────────────────┐           │
│  │  FEATURE PROVIDERS (autodispose)      │           │
│  │  • monitoringProvider (M02)           │           │
│  │  • gmpFormProvider (M03)              │           │
│  │  • ghpChecklistProvider (M04)         │           │
│  │  • wasteProvider (M05)               │           │
│  │  • reportsProvider (M06)             │           │
│  │  • hrProvider (M07)                  │           │
│  │  • settingsProvider (M08)            │           │
│  └───────────────────────────────────────┘           │
└─────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Zasada:** Core Providers (`authProvider`, `currentZoneProvider`) **NIE** używają `autoDispose`. Feature Providers **ZAWSZE** używają `autoDispose`, aby zwolnić zasoby po opuszczeniu modułu.

---

## 3. Decyzja: Routing → **GoRouter** (go_router)

### Uzasadnienie wyboru GoRouter

| Powód | Szczegóły |
|:------|:----------|
| Deklaratywny routing | Mapowanie 33 ekranów na ścieżki URL (przyszłościowe — deep linking) |
| Redirecty/Guards | `redirect` callback → sprawdzenie `authProvider` (czy user jest zalogowany) i `role` (guard na M07/M08) |
| Nested navigation | ShellRoute dla Dashboard Hub z podstronami modułów |
| Oficjalne wsparcie | Pakiet flutter.dev, aktywnie rozwijany |

### Pakiet

```yaml
dependencies:
  go_router: ^14.8.1
```

### Mapa Routingu — 33 Ekrany

```
/                           → SplashScreen (1.1) — auto-redirect po 2s
/login                      → PinPadScreen (1.2)
/zone-select                → ZoneSelectionScreen (1.3)

/hub                        → DashboardHubScreen (Dashboard Hub)

/monitoring                 → TemperatureDashboardScreen (2.1)
/monitoring/chart/:deviceId → SensorChartScreen (2.2)
/monitoring/alarms          → AlarmsPanelScreen (2.3)

/gmp                        → GmpProcessSelectorScreen (3.1)
/gmp/roasting               → MeatRoastingFormScreen (3.2)
/gmp/cooling                → FoodCoolingFormScreen (3.3)
/gmp/delivery               → DeliveryControlFormScreen (3.4)
/gmp/history                → GmpHistoryScreen (3.5)

/ghp                        → GhpCategorySelectorScreen (4.1)
/ghp/personnel              → GhpPersonnelChecklistScreen (4.2)
/ghp/rooms                  → GhpRoomsChecklistScreen (4.3)
/ghp/maintenance            → GhpMaintenanceChecklistScreen (4.4)
/ghp/chemicals              → GhpChemicalsRegistryScreen (4.5)
/ghp/history                → GhpHistoryScreen (4.6)

/waste                      → WastePanelScreen (5.1)
/waste/register             → WasteRegistrationFormScreen (5.2)
/waste/camera               → WasteCameraScreen (5.3)
/waste/history              → WasteHistoryScreen (5.4)

/reports                    → ReportsPanelScreen (6.1)
/reports/preview/:reportId  → PdfPreviewScreen (6.2)
/reports/drive              → DriveStatusScreen (6.3)

/hr                         → HrDashboardScreen (7.1)
/hr/employee/:employeeId    → EmployeeProfileScreen (7.2)
/hr/add                     → AddEmployeeScreen (7.3)
/hr/list                    → EmployeeListScreen (7.4)

/settings                   → GlobalSettingsScreen (8.1)
```

> [!NOTE]
> Ekrany 9.1–9.3 **nie mają ścieżek** — to overlay/widget, nie Route.

### Strategia Guardów (redirect)

```dart
// Pseudokod — app_router.dart
GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final employee = ref.read(authProvider);
    final isLoggedIn = employee != null;
    final isAuthRoute = state.matchedLocation == '/' 
                     || state.matchedLocation == '/login';

    // Guard 1: Niezalogowany → wymuś login
    if (!isLoggedIn && !isAuthRoute) return '/login';

    // Guard 2: Zalogowany na stronie logowania → do hub
    if (isLoggedIn && isAuthRoute) return '/hub';

    // Guard 3: Role-based (M07 HR, M08 Settings)
    final isManagerRoute = state.matchedLocation.startsWith('/hr')
                        || state.matchedLocation.startsWith('/settings');
    if (isManagerRoute && employee?.role != 'manager' 
                       && employee?.role != 'owner') {
      return '/hub'; // Ciche przekierowanie
    }

    return null; // Brak przekierowania
  },
  routes: [ ... ]
);
```

### Kluczowa decyzja: Flat Routes (nie ShellRoute)

Odrzucam `ShellRoute` z `BottomNavigationBar` ponieważ:

- Aplikacja działa na tabletach w trybie Kiosk — nawigacja opiera się o **Dashboard Hub** (centralny punkt powrotu), nie o dolną belkę nawigacji.
- Każdy moduł to osobna „ścieżka" z przyciskiem Back → Hub. Prostota > złożoność.

---

## 4. Kontrakty Integracyjne: Warstwa Supabase

### 4.1 Architektura Warstwowa (Clean Architecture Lite)

```
┌──────────────────────────────────────────┐
│            UI (Screens)                  │  ← Widgety, formularze
│  ref.watch(provider)                     │
├──────────────────────────────────────────┤
│         STATE (Riverpod Providers)        │  ← Logika prezentacyjna
│  StateNotifier / AsyncNotifier            │
├──────────────────────────────────────────┤
│         DATA (Repositories)               │  ← Logika dostępu do danych
│  AuthRepository, GmpRepository, etc.      │
├──────────────────────────────────────────┤
│         INFRA (Supabase Client)           │  ← Singleton klient
│  Supabase.instance.client                 │
└──────────────────────────────────────────┘
```

### 4.2 Centralny Serwis Supabase

**Plik:** `lib/core/services/supabase_service.dart`

Cel: Jeden punkt dostępu do instancji Supabase. Repozytoria **nigdy** nie importują `supabase_flutter` bezpośrednio — zawsze przez ten serwis.

```dart
// Kontrakt (pseudokod)
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Wygodne accessory
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
  static RealtimeClient get realtime => client.realtime;
}
```

### 4.3 Wzorzec Repository — Kontrakt

Każdy moduł posiada **jeden** Repository, który enkapsuluje wszystkie operacje na Supabase dla danej domeny.

| Moduł | Repository | Tabele Supabase | Kluczowe metody |
|:------|:-----------|:----------------|:----------------|
| M01 | `AuthRepository` | `employees`, `employee_zones`, `zones` | `loginWithPin()`, `getZonesForEmployee()` |
| M02 | `MeasurementsRepository` | `measurements`, `devices`, `temperature_logs` | `streamRealtime()`, `acknowledgeAlert()`, `getHistoricalData()` |
| M03 | `GmpRepository` | `gmp_logs` | `insertLog()`, `getHistory()`, `getTodayCount()` |
| M04 | `GhpRepository` | `ghp_logs` | `insertChecklist()`, `getHistory()` |
| M05 | `WasteRepository` | `waste_records` + Storage | `insertRecord()`, `uploadPhoto()`, `getHistory()` |
| M06 | `ReportsRepository` | Agregacja SQL + Drive API | `generatePdf()`, `syncToDrive()`, `getReportsList()` |
| M07 | `HrRepository` | `employees` (profiles) | `getAlerts()`, `updateSanepid()`, `toggleActive()` |
| M08 | `SettingsRepository` | `venue_settings` | `getSettings()`, `updateSettings()` |

### 4.4 Reguła Złota: Repository → Provider → Screen

```
Screen (UI)
  └── ref.watch(gmpProvider)        // Riverpod Provider
        └── GmpRepository.insertLog()  // Repository
              └── SupabaseService.client.from('gmp_logs').insert(...)  // Supabase
```

> [!CAUTION]
> **ZAKAZ:** Ekrany (`*_screen.dart`) **NIGDY** nie mogą wywoływać `Supabase.instance.client` bezpośrednio. Zawsze przez Repository → Provider. Złamanie tej zasady = Code Review Rejection.

---

## 5. Kluczowe Zależności (pubspec.yaml) — Pełna Lista

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.8.4
  
  # Env
  flutter_dotenv: ^5.2.1
  
  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Routing
  go_router: ^14.8.1
  
  # Charts (M02)
  fl_chart: ^0.70.2
  
  # PDF (M06)
  syncfusion_flutter_pdfviewer: ^28.1.33  # lub flutter_pdfview
  
  # Camera (M05)
  camera: ^0.11.0+2
  image: ^4.5.3            # Kompresja zdjęć
  
  # Connectivity (M09 - offline banner)
  connectivity_plus: ^6.1.3
  
  # Hashing (M01 - PIN)
  crypto: ^3.0.6
  
  # Fonts
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.14
  flutter_lints: ^5.0.0
```

---

## 6. Plan Realizacji — Sprint Map (2 tygodnie)

| Dzień | Sprint | Moduł | Zakres | Blokery |
|:------|:-------|:------|:-------|:--------|
| **1** | S0 | Setup | `flutter create`, pubspec, `.env`, theme, GoRouter skeleton, ProviderScope | Potrzebne klucze `SUPABASE_URL` i `SUPABASE_ANON_KEY` w `.env` |
| **2** | S1 | M01 | Directive 02 (AuthRepository), SplashScreen, PinPadScreen, ZoneSelectionScreen | Directive 01 (SQL) musi być wykonana w Supabase |
| **3** | S1 | Dashboard | DashboardHubScreen + routing do wszystkich modułów + badge queries | — |
| **4** | S2 | M02 | TemperatureDashboard, SensorChart (fl_chart), AlarmPanel, Realtime subscription | Dane testowe w `measurements` |
| **5** | S2 | M03 | 4 formularze GMP + historia, HaccpStepper, HaccpTimePicker | — |
| **6** | S3 | M04 | 5 checklist GHP + historia, HaccpToggle z expand-komentarz | — |
| **7** | S3 | M05 | Panel odpadów, formularz, Camera integration, Storage upload | Bucket `waste-docs` w Storage |
| **8** | S4 | M06 | Panel raportów, PDF viewer, Drive status (mock) | Google Drive Service Account |
| **9** | S4 | M07 | HR Dashboard, Profil, Dodaj Pracownika, Lista | — |
| **10** | S4 | M08/M09 | Ustawienia, Success Overlay, Empty State, Offline Banner | — |
| **11–12** | QA | All | Integration testing, UX polish, Glove-Friendly audit | Tablet fizyczny |
| **13–14** | Deploy | All | APK build, instalacja na tabletach, testy Sanepid-ready | — |

---

## 7. Decyzje Architektoniczne (Zamrożone)

1. **Zmienne Środowiskowe:** Klucze `SUPABASE_URL` i `SUPABASE_ANON_KEY` są wdrożone w pliku `.env`.
2. **Baza Danych:** Schemat SQL (M01: `employees`, `zones`, `employee_zones`) jest wdrożony i aktywny.
3. **Motyw UI:** Wymuszamy **Dark Mode** (tło Onyx/Charcoal) zgodnie z plikiem `UI_description.md`.
4. **Synchronizacja Danych (Two-Stage Streaming):** Supabase Realtime nie obsługuje filtrów po JOINach. Wdrażamy architekturę dwuetapową: subskrypcja globalna na `venue_id` + filtrowanie strefy w warstwie Providera (`MonitoringProvider`).
5. **Autoryzacja Usług:** Plik `credentials.json` (Google Service Account) będzie używany współdzielenie dla Google Stitch oraz do automatyzacji w Google Drive API (M06).
6. **Enforcement "Glove-Friendly":** Wszystkie krytyczne akcje (Zapisz/Potwierdź) MUSZĄ używać `HaccpLongPressButton` (1s). Touch target min. 60x60dp jest twardym warunkiem architektonicznym.
7. **Alarm Acknowledgement:** Logujemy potwierdzenia bezpośrednio w `temperature_logs` (kolumny `is_acknowledged`, `acknowledged_by`), eliminując potrzebę osobnej tabeli junction dla uproszczenia zapytań realtime.
8. **Strategia RLS dla Sessionless Auth:** Ponieważ aplikacja w trybie Kiosk często korzysta z autoryzacji anonimowej (`signInAnonymously()`), polityki RLS dla tabel odczytowych (`sensors`, `temperature_logs`) muszą obejmować zarówno rolę `authenticated`, jak i `anon`, aby zapobiec blokadzie danych przy błędach sesji.
