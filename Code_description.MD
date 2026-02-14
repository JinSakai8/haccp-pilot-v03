# Code Roadmap: HACCP Pilot v03-00

Witamy w projekcie **HACCP Pilot**. Ten dokument pomoże Ci zrozumieć obecną strukturę kodu, kluczowe decyzje architektoniczne i sposób, w jaki budujemy nowe funkcje.

## 1. Filozofia Projektu

- **Glove-Friendly UX:** Wszystkie elementy interaktywne muszą mieć min. **60x60dp**. Unikamy klawiatury systemowej (korzystamy z `HaccpNumPad` lub gotowych opcji).
- **Dark Mode Only:** Aplikacja działa tylko w trybie ciemnym (kuchennym).
- **Offline-First / Online-Integration:** Dane są zbierane lokalnie, a synchronizacja (np. zdjęcia) następuje przy finalizacji.

## 2. Struktura Folderów (`lib/`)

Projekt podzielony jest na **Features** (funkcjonalności) i **Core** (wspólne utilities).

```
lib/
├── core/                  # Fundamenty aplikacji
│   ├── config/            # Env, stałe konfiguracyjne
│   ├── constants/         # Design Tokens (kolory, wymiary)
│   ├── router/            # GoRouter (nawigacja)
│   ├── theme/             # Motyw Fluttera (Dark Theme)
│   └── widgets/           # Globalne widgety (TopBar, Tile)
│
├── features/              # Moduły biznesowe (M01, M02, ...)
│   ├── m01_auth/          # Logowanie (PIN Pad)
│   ├── m02_monitoring/    # IoT (Dashboard temperatur)
│   ├── m03_gmp/           # Procesy produkcyjne (Pieczenie itp.)
│   │   └── screens/       # Ekrany specyficzne dla modułu
│   │
│   └── shared/            # !!! KLUCZOWY MODUŁ WSPÓLNY !!!
│       ├── models/        # Modele silnika formularzy (FormDefinition)
│       ├── providers/     # Logika Riverpod (DynamicFormNotifier)
│       └── widgets/       # Komponenty formularzy (Stepper, Toggle)
```

## 3. Silnik Formularzy Dynamicznych (The Engine)

Większość ekranów w M03 (GMP) i M04 (GHP) to formularze. Zamiast pisać każdy ekran ręcznie, stworzyliśmy **silnik**, który buduje UI na podstawie konfiguracji (JSON-like).

### Kluczowe Pliki

1. **`lib/features/shared/widgets/dynamic_form/dynamic_form_renderer.dart`**
    - To jest "Serce". Bierze listę `FormFieldConfig` i zamienia ją na widgety (`ListView`).
    - Obsługuje **Non-Blocking Policy**: Jeśli parametr jest poza normą (np. temp < 75°C), pojawia się ostrzeżenie i *wymuszone pole komentarza*. Nie blokujemy zapisu!

2. **`lib/features/shared/providers/dynamic_form_provider.dart`**
    - Zarządza stanem (wartościami pól, błędami walidacji, widocznością).
    - Używa **Riverpod** (`autoDispose`), więc stan czyści się po wyjściu z ekranu.

3. **Modele (`lib/features/shared/models/form_definition.dart`)**
    - `FormDefinition`: Lista pól.
    - `FormFieldConfig`: Konfiguracja pojedynczego pola (typ, label, min/max, wymagane).

### Glove-Friendly Widgets

Te komponenty znajdują się w `lib/features/shared/widgets/dynamic_form/`:

- **`HaccpStepper`**: Wielkie przyciski `+` / `-` do wprowadzania liczb (np. temperatura).
- **`HaccpToggle`**: Kafelki `OK` (zielony) / `PROBLEM` (czerwony) zamiast małych switchy.
- **`HaccpNumPadInput`**: Pole tekstowe (read-only), które po kliknięciu otwiera dużą klawiaturę numeryczną w BottomSheet.

## 4. Jak dodać nowy ekran procesu (np. Chłodzenie)?

Nie musisz budować całego UI od zera.

1. Stwórz nowy plik w `lib/features/m03_gmp/screens/` (np. `cooling_form_screen.dart`).
2. Zdefiniuj strukturę formularza w zmiennej `FormDefinition`:

    ```dart
    final coolingFormDef = FormDefinition(
      fields: [
        FormFieldConfig(
          id: 'temp_start',
          type: HaccpFieldType.stepper,
          label: 'Temp. Początkowa',
          config: {'min': 0, 'max': 100},
        ),
        // ... więcej pól
      ],
    );
    ```

3. Użyj `DynamicFormRenderer` w metodzie `build`:

    ```dart
    return Scaffold(
      body: DynamicFormRenderer(
        formId: 'cooling_process',
        definition: coolingFormDef,
      ),
    );
    ```

4. Podepnij stan pod przycisk "Zapisz", aby sprawdzić `isValid`.

## 5. State Management (Riverpod)

Używamy generatorów kodu (`riverpod_annotation`).

- Jeśli zmienisz cokolwiek w plikach z adnotacją `@riverpod`, musisz uruchomić:
    `dart run build_runner build --delete-conflicting-outputs`
- Provider logiczny formularza to `dynamicFormProvider`.

## 6. Moduł M02 (Monitoring IoT)

Ten moduł jest nieco inny – służy do podglądu danych "na żywo".

- Ekrany: `TemperatureDashboardScreen`.
- UI: Karty sensorów zmieniają kolor zależnie od odchyłki od normy (Zielony/Pomarańczowy/Czerwony).

## 7. Moduł M05 (Odpady & Aparat)

Ten moduł wprowadza natywną obsługę kamery bez interfejsu systemowego (Glove-Friendly).

### Kluczowe Komponenty

1. **`lib/features/m05_waste/screens/haccp_camera_screen.dart`**
    - Specjalny ekran aparatu używający paczki `camera`.
    - Brak małych przycisków systemowych.
    - **Gigantyczny spust migawki (100dp).**
    - Tryb "Review": Wielkie przyciski "PONÓW" (Orange) i "ZATWIERDŹ" (Green).

2. **`lib/core/services/storage_service.dart`**
    - Obsługuje kompresję zdjęć (max 1024px, quality 80%).
    - Wysyła pliki do Supabase Storage (`waste-docs`).
    - Zwraca ścieżkę do pliku, którą zapisujemy w bazie.

3. **`HaccpLongPressButton`**
    - Widget bezpieczeństwa. Wymaga przytrzymania przycisku przez 1 sekundę, aby zatwierdzić akcję (np. wysłanie zdjęcia, zapis formularza). Zapobiega przypadkowym kliknięciom w pośpiechu.

### Przepływ Danych M05

1. **Panel Odpadów** (`WastePanelScreen`): Pobiera ostatnie wpisy z `waste_records`.
2. **Rejestracja**: Użytkownik wybiera typ (Kafelki), wagę (Stepper) i firmę.
3. **Zdjęcie**:
    - Otwiera `HaccpCameraScreen`.
    - Robi zdjęcie ->Zatwierdź -> Kompresja -> Upload -> Return Path.
4. **Zapis**: Formularz wysyła komplet danych (z path zdjęcia) do `WasteRepository`.

---

## 8. Moduł M06 (Raportowanie & Drive)

Moduł odpowiedzialny za generowanie dokumentacji i archiwizację w chmurze.

### Generowanie PDF (`PdfService`)

- **Silnik**: `syncfusion_flutter_pdf`.
- **Izolacja**: Generowanie odbywa się w osobnym wątku (`compute`), aby nie blokować UI.
- **Dynamiczność**: Wykorzystuje `FormDefinition` do automatycznego tworzenia kolumn tabeli na podstawie pól formularza. Jeśli dodasz pole w configu, pojawi się w PDF.
- **Zdjęcia**: Pobiera zdjęcia (z URL lub pliku), skaluje je i dołącza pod tabelą raportu.

### 2.3 Web Compatibility & Platform Specifics

- **NO `dart:io`**: The application is strictly web-compatible. All usages of `dart:io` (`File`, `Platform`, etc.) have been removed or guarded with `kIsWeb`.
- **Blob/Data Storage**: Files (images, PDFs) are handled as `Uint8List` in memory or uploaded directly to Supabase Storage/Google Drive without local filesystem intermediate steps.
- **Printing/PDF**: `pdf` package is used for generation. `printing` package handles web printing/preview. `syncfusion_flutter_pdf` is used for advanced PDF creation.

## 3. Key Modules & Providers

### Core

- `auth_provider.dart`: Global auth state (Supabase User + Employee Profile).
- `app_router.dart`: GoRouter configuration with AuthGuard.
- `pdf_service.dart`: Universal PDF generation (Web/Mobile).
- `drive_service.dart`: Google Drive API integration (Web-compatible via HTTP).
- `storage_service.dart`: Supabase Storage wrapper.

### Feature Modules

- **M01 Login**: PIN/Password handlers.
- **M05 Waste**: Waste registration, Photo upload (Direct binary upload), History.
- **M06 Reports**: PDF generation (`ReportData` state), Google Drive export. `reportsProvider` handles state.
- **M08 Settings**: Venue settings, Logo upload (Uint8List).

## 4. Deployment & Build

- **Vercel**: Automated CI/CD.
- **Build Script**: `vercel_build.sh` handles Flutter setup and build.
- **Command**: `bash vercel_build.sh`
- **Output**: `build/web`

### Google Drive (`DriveService`)

- **Auth**: Service Account (plik `assets/credentials.json`). Nie wymaga logowania użytkownika "na tablecie".
- **Folder**: ID folderu docelowego jest w `.env`.
- **Funkcje**: Upload plików (`uploadReport`) oraz listowanie zawartości folderu (`listFiles`).

---

## 9. Moduł M07 (HR & Personel)

Moduł do zarządzania pracownikami, ich rolami (Manager/Pracownik) oraz ważnością badań Sanepid.

### Struktura (`lib/features/m07_hr/`)

- **Repositories**: `HrRepository` - obsługuje tabelę `employees`, haszowanie PIN (SHA-256) oraz sprawdzanie unikalności PIN.
- **Providers**: `HrProvider` - zarządza listą pracowników i logiką dodawania/edycji.
- **Ekrany**:
  - `EmployeeListScreen`: Lista z filtrowaniem (Wszyscy/Aktywni/Wygasające).
  - `AddEmployeeScreen`: Dodawanie pracownika z **weryfikacją unikalności PIN na żywo**.
  - `HrDashboardScreen`: Panel główny z alertami o wygasających badaniach (czerwone/żółte kropki).

### Kluczowe funkcje

- **Role Guards**: Tylko `manager` i `owner` mają dostęp do tras `/hr/*`. Zaimplementowane w `AppRouter`.
- **Sanepid Status**: Wizualizacja statusu badań (Zielony > 30 dni, Żółty < 30 dni, Czerwony = po terminie).

---

## 10. Moduł M08 (Ustawienia & Polish)

Moduł zamykający, obsługujący dane lokalu i łączność.

### Ustawienia Lokalu (`VenueRepository`)

- Pozwala na zmianę nazwy lokalu, NIPu i adresu.
- **Logo Upload**: Użytkownik może wgrać logo, które jest zapisywane w bucket `branding`.
- **PDF Integration**: Logo jest automatycznie pobierane i wstawiane do nagłówka każdego generowanego raportu PDF.

### Connectivity & Offline Mode

- **`ConnectivityService`**: Nasłuchuje zmian stanu sieci.
- **UI**: W `HaccpTopBar` pojawia się czerwona ikona "Cloud Off", gdy tablet straci połączenie. Aplikacja nie blokuje pracy (Offline-First), ale ostrzega użytkownika.

### UX Audit (Glove-Friendly Polish)

- Przycisk "Zapisz" w ustawieniach używa `HaccpLongPressButton` (wymaga przytrzymania).
- Wszystkie kluczowe interakcje są przystosowane do obsługi w rękawiczkach.

---

## 11. Security Hardening (Directive 10a)

Wdrożono zaawansowane mechanizmy bezpieczeństwa zgodnie z audytem 10a.

### Brute-Force Protection

- **Logika**: 5 błędnych prób = 30s blokady. 10 prób = 5min. 20 prób = 30min.
- **UI**: Ekran `PinPadScreen` blokuje klawiaturę i wyświetla odliczanie.
- **State**: Stan blokady jest trzymany w pamięci (`PinLoginNotifier`), resetowany po upływie czasu.

### Data Access Layer

- **RLS (Row Level Security)**: Włączono w Supabase dla tabeli `employees`.
- **Public View**: `HrRepository` korzysta z bezpiecznego widoku `public_employees`, który fizycznie wyklucza kolumnę `pin_hash` z wyników zapytania.
- **Audit Columns**: Tabele posiadają `created_by` i `updated_by` uzupełniane automatycznie przez trigger `handle_updated_at` i `handle_audit`.

### Credential Safety

- **.gitignore**: Plik `assets/credentials.json` oraz `.env` są ignorowane przez system kontroli wersji.
- **Error Handling**: W produkcji (`kReleaseMode`) stack trace błędu inicjalizacji jest ukryty przed użytkownikiem.

---

## 12. Architecture Master Plan Compliance (Directive 14)

Wdrożono rygorystyczne standardy architektoniczne zapewniające skalowalność i łatwość utrzymania 33+ ekranów.

### Feature-First Isolation

- Każdy moduł (M01-M08) posiada własny folder `repositories/` i `providers/`.
- **Zakaz współdzielenia repozytoriów logów:** M03 korzysta z `GmpRepository`, M04 z `GhpRepository`. Zapobiega to "God Object" w warstwie danych.

### Wzorzec Repository -> Provider -> Screen

1. **Repository**: Czysty dostęp do Supabase (np. `gmp_repository.dart`).
2. **Provider**: `AsyncNotifier` (np. `gmp_provider.dart`), który zarządza stanem ładowania i błędów.
3. **Screen**: Reaguje na stan providera (`ref.watch`) i wyświetla `SuccessOverlay` po udanym zapisie.

### Glove-Friendly Safety (Long Press)

- **HaccpLongPressButton**: Zgodnie z Master Planem, każdy przycisk typu "ZAPISZ" lub "ZATWIERDŹ" w modułach operacyjnych (M03, M04, M05) musi być przyciskiem typu Long Press. Eliminuje to błędy wynikające z przypadkowych dotknięć ekranu mokrą ręką lub w rękawicy.

### Unified Connectivity Logic

- **isOnlineProvider**: Centralny provider zwracający `bool`.
- **OfflineBanner**: Widget w `core/widgets/` reagujący na brak sieci w czasie rzeczywistym.

---

## 13. Baza Danych (Supabase)

System opiera się na relacyjnej bazie PostgreSQL hostowanej w Supabase. Dostęp do danych odbywa się wyłącznie przez warstwę repoyztoriów (`repositories/`), które komunikują się z API Supabase.

### 13.1 Schemat Tabel

Poniżej przedstawiono strukturę głównych tabel wykorzystywanych w poszczególnych modułach.

| Tabela | Moduł(y) | Opis | Kluczowe Kolumny |
|:---|:---|:---|:---|
| **`employees`** | M01, M07 | Pracownicy i uprawnienia | `id`, `full_name`, `pin_hash`, `role` (owner/manager/cook), `is_active`, `sanepid_expiry` |
| **`zones`** | M01 | Strefy w lokalu (np. Kuchnia) | `id`, `name`, `venue_id` |
| **`employee_zones`** | M01 | Przypisanie pracownika do strefy | `employee_id`, `zone_id` |
| **`sensors`** | M02 | Fizyczne czujniki IoT | `id`, `name`, `zone_id`, `is_active` |
| **`measurements`** | M02 | Logi temperatur (Realtime) | `id`, `sensor_id`, `temperature_celsius`, `timestamp` |
| **`haccp_logs`** | M03, M04 | Zunifikowane logi GMP i GHP | `id`, `category` (gmp/ghp), `form_id`, `data` (JSONB), `user_id`, `zone_id`, `created_at` |
| **`waste_records`** | M05, M06 | Rejestr odpadów | `id`, `venue_id`, `waste_type`, `mass_kg`, `photo_url`, `created_at` |
| **`venues`** | M08 | Ustawienia lokalu | `id`, `name`, `address`, `nip`, `logo_url` |
| **`public_employees`** | M07 | Widok bezpieczny (bez hashy PIN) | (View) `id`, `full_name`, `role`, `is_active` |

### 13.2 Przepływ Danych (Data Flow)

Każdy moduł implementuje specyficzne zapytania do bazy. Poniżej zestawienie operacji.

#### **M01: Autoryzacja (`AuthRepository`)**

- **Zapytanie (Secure RPC):** `login_with_pin(pin_input)` (Funkcja PostgreSQL `SECURITY DEFINER`).
- **Cel:** Ominięcie blokady RLS dla użytkownika anonimowego przy weryfikacji hasha PIN.
- **Zwrot:** Obiekt `Employee` (token sesji w aplikacji, brak JWT od Supabase w trybie Kiosk).
- **Strefy:** `SELECT` z `employee_zones` join `zones`.

#### **M02: Monitoring (`MeasurementsRepository`)**

- **Zapytanie:** `STREAM` (Subscribe) na tabelę `temperature_logs` (lub `measurements`).
- **Zwrot:** Strumień listy `TemperatureLog` (ostatnie 20 wpisów sortowane po czasie).
- **Czujniki:** `SELECT` z `sensors` dla danej strefy.

#### **M03 (GMP) & M04 (GHP) (`GmpRepository` / `GhpRepository`)**

- **Zapis:** `INSERT` do tabeli `haccp_logs`.
  - Rozróżnienie rekordów poprzez kolumnę `category`: `'gmp'` lub `'ghp'`.
  - Dane formularza (temperatury, odpowiedzi tak/nie) lądują w kolumnie `data` jako JSONB.
- **Odczyt (Historia):** `SELECT` z `haccp_logs` filtrowane po `category` i `zone_id`.
- **Zwrot:** Lista map JSON.

#### **M05: Odpady (`WasteRepository`)**

- **Zapis:**
    1. Upload zdjęcia do Storage (`waste-docs`).
    2. `INSERT` do `waste_records` z otrzymanym `photo_url`.
- **Odczyt:** `SELECT` z `waste_records` dla danego `venue_id`.

#### **M06: Raporty (`ReportsRepository`)**

- **Odczyt:** Agregacja danych z `waste_records`, `measurements` oraz logów.
- **UWAGA:** Raporty korzystają teraz z ujednoliconej tabeli `haccp_logs`.

#### **M07: HR (`HrRepository`)**

- **Odczyt:** `SELECT` z widoku `public_employees` (bezpieczne listowanie).
- **Zapis:** `INSERT`/`UPDATE` na tabeli `employees` (wymaga RLS role='manager'/'owner' - w trybie kiosk symulowane przez logikę aplikacji guarding routes).

#### **M08: Ustawienia (`VenueRepository`)**

- **Zapis:** `UPDATE` na tabeli `venues`.
- **Logo:** Upload do bucketu `branding`, zapis URL w `venues.logo_url`.

### 13.3 Bezpieczeństwo (RLS & Policies)

Mimo trybu Kiosk (gdzie często używa się jednego Service Role lub anonimowego dostępu), wdrożono RLS:

1. **Employees:** Dostęp do `pin_hash` jest zablokowany dla zwykłych zapytań `SELECT *`. Dostęp tylko przez RPC `login_with_pin`.
2. **Audit:** Trigger `handle_updated_at` automatycznie uzupełnia czasy edycji.
3. **Storage:** Buckety `waste-docs` i `branding` mają polityki `SELECT` public (lub authenticated) oraz `INSERT` tylko dla uwierzytelnionych sesji (Anonimowych).

---

## 14. Log Zmian w Bazie Danych (Naprawy Krytyczne)

W dniu 2026-02-14 przeprowadzono serię napraw struktury bazy danych w celu przywrócenia funkcjonalności logowania i stref.

1. **RPC Login (`12_auth_rpc.sql`)**: Wdrożono funkcję `login_with_pin` w celu bezpiecznej weryfikacji PIN bez naruszania RLS.
2. **Anonymous Auth (`13_fix_haccp_logs.sql`)**:
    - Aplikacja wykonuje teraz `signInAnonymously()`.
    - Utworzono brakującą tabelę `haccp_logs` (zamiast rozdzielnych `gmp`/`ghp`) i zabezpieczono ją RLS.
3. **Data Integrity (`14_data_fix_hashes.sql`)**:
    - Zaktualizowano PINy w tabeli `employees` z wersji plain text (`1234`) na hashe SHA-256.
4. **Venues & Zones Fix (`15/16_fix_venues_and_zones.sql`)**:
    - Utworzono brakującą tabelę `venues`.
    - Dodano kolumnę `venue_id` do tabeli `zones`.
    - Przywrócono spójność danych poprzez przypisanie wszystkich stref do domyślnego lokalu.

---
Autor: Antigravity (AI Agent)
Data wersji: 2026-02-14 (Post-Fix Database Update)
