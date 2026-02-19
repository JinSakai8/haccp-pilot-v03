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

### 14.1 Moduł M06: Raporty Temperatur (Detale Techniczne)

Raporty temperatur są najbardziej złożonym elementem modułu M06 ze względu na wolumen danych (tysiące pomiarów na sensor miesięcznie).

#### Proces Generowania

1. **Pobieranie Danych (`ReportsRepository.getMeasurements`)**:
    - Zapytanie do tabeli `temperature_logs`.
    - **Data Join**: Wykonujemy `JOIN` z tabelą `sensors`, aby uzyskać czytelne nazwy urządzeń (np. "Chłodnia Mięso") zamiast surowych identyfikatorów UUID.
    - Filtrowanie: Po zakresie dat (cały miesiąc) oraz opcjonalnie po konkretnym `sensor_id`.
2. **Agregacja (`TemperatureAggregatorService`)**:
    - Ponieważ wyświetlanie każdego pomiaru (co 5 min) zajęłoby setki stron, dane są agregowane do **statystyk dziennych**.
    - Dla każdego dnia i każdego urządzenia wyliczane są: `min`, `max`, `avg` oraz `measurement_count`.
    - System sprawdza również wystąpienie alarmów krytycznych (breaches).
3. **Generowanie Wizualne (`HtmlReportGenerator`)**:
    - Agregaty są przekazywane do generatora HTML.
    - Tworzony jest profesjonalny dokument HTML z sekcją podsumowania (Summary Cards) i tabelą szczegółową.
    - Stylizacja oparta jest na CSS zgodnym z designem aplikacji (akcenty `#D2661E`).
4. **Podgląd i Druk**:
    - Wygenerowany kod HTML jest konwertowany na PDF (lub renderowany bezpośrednio w widoku Web) i otwierany za pomocą `FileOpener`.

#### Źródła Danych (Database Mapping)

- **Tabela:** `temperature_logs` (pomiary).
- **Relacja:** `sensors_id` -> `sensors.id` (nazwa urządzenia).
- **Branding:** Nazwa lokalu i logo pobierane są z tabeli `venues` via `VenueRepository`.

---

### Generowanie Raportów (M06)

- **Raporty PDF (`PdfService`)**: Używa `syncfusion_flutter_pdf` do generowania raportów GMP/GHP i Odpadów.
- **Raporty Temperatur (HTML)**: Ze względu na dużą ilość danych (tysiące pomiarów miesięcznie), raporty temperatur są najpierw agregowane do statystyk dziennych (`TemperatureAggregatorService`), a następnie renderowane do formatu HTML (`HtmlReportGenerator`).
- **Agregacja**: Wylicza Min, Max i Średnią temperaturę dla każdego urządzenia w każdym dniu miesiąca.
- **Wyróżnienie Alarmów**: HTML automatycznie koloruje na czerwono wartości przekraczające progi (np. > 8°C dla lodówek).
- **Otwieranie plików**: Wykorzystuje `FileOpener` do podglądu HTML/PDF w nowej karcie przeglądarki (Web).

### 2.3 Web Compatibility & Platform Specifics

- **NO `dart:io`**: Aplikacja jest w pełni kompatybilna z Web. Wszystkie użycia `dart:io` zostały usunięte lub zabezpieczone przez `kIsWeb`.
- **File Opener (`lib/core/services/file_opener.dart`)**: Specjalny helper wykorzystujący **warunkowe importy** (`dart:html` na web, stub na mobile). Pozwala na otwieranie wygenerowanych raportów bezpośrednio w nowej karcie przeglądarki.
- **Blob Handling**: Pliki są obsługiwane jako `Uint8List` w pamięci, co eliminuje potrzebę zapisu na dysku lokalnym przed wysyłką do Supabase/Drive.
- **Printing**: Raporty HTML są zoptymalizowane pod kątem wydruku systemowego (`@media print`).

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

- **Repositories**: `HrRepository` - obsługuje tabelę `employees` poprzez **Secure RPCs**, co pozwala na bezpieczne modyfikacje przez użytkowników anonimowych (Kiosk mode).
- **Providers**: `HrProvider` - zarządza listą pracowników i logiką dodawania/edycji.
- **Ekrany**:
  - `EmployeeListScreen`: Lista z filtrowaniem i feedbackiem "Pracownik dodany".
  - `AddEmployeeScreen`: Dodawanie pracownika z blokadą przycisku dla duplikatów PIN oraz **przypisywaniem stref (Zones)**.
  - `EmployeeProfileScreen`: Profil z obsługą błędów przełącznika statusu i **aktualizacją daty Sanepid** z potwierdzeniem.

### Kluczowe funkcje

- **Role Guards**: Tylko `manager` i `owner` mają dostęp do tras `/hr/*`. Zaimplementowane w `AppRouter`.
- **Sanepid Status**: Wizualizacja statusu badań (Zielony > 30 dni, Żółty < 30 dni, Czerwony = po terminie).

---

## 10. Moduł M08 (Ustawienia & Polish)

Moduł zamykający, obsługujący dane lokalu i łączność.

### Ustawienia Lokalu (`VenueRepository`)

- Pozwala na zmianę nazwy lokalu, NIPu i adresu.
- **Logo Upload**: Użytkownik może wgrać logo using `file_picker` (działa na Web), które jest zapisywane w bucket `branding`.
- **Sensory Config**: Ustawianie interwału pomiarów (5/15/60 min) i progu alarmowego dla sensorów.
- **PDF Integration**: Logo jest automatycznie pobierane i wstawiane do nagłówka każdego generowanego raportu PDF.

### Connectivity & Offline Mode

- **`ConnectivityService`**: Nasłuchuje zmian stanu sieci.
- **UI**: W `HaccpTopBar` pojawia się czerwona ikona "Cloud Off", gdy tablet straci połączenie. Aplikacja nie blokuje pracy (Offline-First), ale ostrzega użytkownika.

### UX Audit (Glove-Friendly Polish)

- Przycisk "Zapisz" w ustawieniach i formularzach używa `HaccpLongPressButton` (wymaga przytrzymania).
- Wszystkie kluczowe interakcje są przystosowane do obsługi w rękawiczkach (przyciski min. 60x60dp).
- **Navigation Safety**: Wdrożono `GoRouter` we wszystkich modułach, eliminując niespójności `Navigatora`.
- **Empty States**: Wprowadzono `HaccpEmptyState` - spójny widget informujący o braku danych (np. historycznych), zastępujący surowe listy.
- **Data Seeding**: Dodano skrypt `18_seed_monitoring.sql` do generowania syntetycznych danych IoT (sensory, pomiary, alerty) dla celów testowych i prezentacyjnych.
- **Monitoring Polish**: Ujednolicono wyświetlanie nazw sensorów w panelu alarmów oraz dodano mechanizmy obronne przed niepoprawnym stanem sesji strefy.

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
| **`generated_reports`** | M06 | Archiwum wygenerowanych PDF | `id`, `venue_id`, `report_type`, `generation_date`, `storage_path`, `created_by` |
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
- **Persistence:** Automatyczny zapis wygenerowanych PDF w tabeli `generated_reports` oraz bucket `reports` w Supabase Storage.
- **Data Range:** Raporty CCP-3 są generowane dla konkretnego dnia na podstawie pola `generation_date`.
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

5. **Report Persistence (`31_create_generated_reports.sql`)**:
    - Wdrożono tabelę `generated_reports` do archiwizacji PDF.
    - Skonfigurowano bucket `reports` z politykami dostępu dla Kiosk/Anon mode.
    - Dodano pole `comments` do formularza chłodzenia (CCP-3) dla działań korygujących.

## 15. Rozwiązywanie Problemów (Troubleshooting)

### 15.1 Vercel Build Errors (Common Issues)

W dniu 2026-02-15 zidentyfikowano i naprawiono szereg błędów blokujących wdrożenie na Vercel. Poniższa lista służy jako referencja przy przyszłych problemach:

1. **Błędy Kompilacji (Compilation Errors):**
    - **Błąd:** `Duplicated parameter name 'address'`.
    - **Powód:** Dwukrotne zdefiniowanie tego samego parametru w sygnaturze metody (np. w `VenueRepository`).
    - **Rozwiązanie:** Usunięcie powtarzającego się parametru.

2. **Brakujące Importy (Missing Imports):**
    - **Błąd:** `Couldn't find constructor 'GhpHistoryScreen'`.
    - **Powód:** Zapomniany import ekranu w pliku `app_router.dart`.
    - **Rozwiązanie:** Regularne sprawdzanie komunikatów builda, które wskazują konkretne pliki i linie.

3. **Błędy Typów w Badge'ach (Dashboard Badges):**
    - **Błąd:** `The getter 'count' isn't defined for the type 'int'`.
    - **Powód:** Metoda `.count()` w nowszych wersjach Supabase SDK zwraca bezpośrednio `int` zamiast obiektu z polem `.count`.
    - **Rozwiązanie:** Bezpośrednie użycie wyniku (np. `if (count > 0)`).

4. **Błędne Referencje Design Tokens:**
    - **Błąd:** `Member not found: 'radiusMedium'`.
    - **Powód:** Odwołanie do nieistniejącego tokenu w `HaccpDesignTokens`.
    - **Rozwiązanie:** Sprawdzenie dostępnych tokenów w `lib/core/constants/design_tokens.dart` i użycie np. `cardRadius`.

5. **Przestarzała Składnia i Kolejność Filtrowania Supabase:**
    - **Błąd:** `The method 'filter' (lub 'in_') isn't defined for the type 'PostgrestTransformBuilder'`.
    - **Powód:** Wywołanie `.order()`, `.limit()` lub `.range()` zmienia typ buildera na `TransformBuilder`, który nie obsługuje już metod filtrujących. Wszystkie filtry (`.eq()`, `.filter()`, `.in_()`) muszą wystąpić **PRZED** metodami sortowania/limitowania.
    - **Rozwiązanie:** Zastąpienie `.in_('col', list)` przez `.filter('col', 'in', list)` oraz przesunięcie `.order()` na sam koniec łańcucha zapytań.

### 15.2 Problem "Stale Cache" na Vercelu

Jeśli build na Vercel **nie powiedzie się (Failed)**, platforma może serwować **poprzednią działającą wersję** aplikacji (cached build).

- **Objaw:** Wprowadziłeś poprawkę (np. usunąłeś hardcoded ID), ale w przeglądarce nadal widzisz stary błąd.
- **Działanie:** Zawsze sprawdzaj status deploymentu w panelu Vercel. Jeśli jest czerwony ("Error"), popraw błędy kompilacji pokazane w logach, zpushuj kod i poczekaj na status "Ready".

## 6. M02 - Monitoring & IoT (Directive 14)

Moduł ten odpowiada za strumieniowe odbieranie danych z czujników temperatury, generowanie alarmów i wizualizację danych. Jest to jeden z najbardziej krytycznych elementów systemu pod kątem wydajności i UX.

### 6.1 Architektura Danych

Z powodu ograniczeń Supabase Realtime (brak możliwości filtrowania po JOIN-ach `measurements` -> `devices` -> `zones`), przyjęto architekturę **dwuetapową (`Two-Stage Streaming`)**:

1. **Global Stream:** Subskrybujemy tabelę `measurements` (INSERT) bez filtrowania po strefie, ale z filtrem `venue_id`.
2. **Local Filtering:** W aplikacji (`MonitoringProvider`) sprawdzamy każde przychodzące zdarzenie payloadu. Jeśli `device_id` pomiaru należy do aktualnie wybranej strefy (mapa `device -> zone` w pamięci), pomiar jest procesowany. W przeciwnym razie jest ignorowany.

Plik odpowiedzialny: `lib/features/m02_monitoring/repositories/measurements_repository.dart`

### 6.2 Kluczowe Komponenty

1. **Repository Layer (`MeasurementsRepository`)**:
    - Obsługuje strumień realtime.
    - Pobiera historię pomiarów (ostatnie 24h) przy starcie.
    - Obsługuje funkcję `acknowledgeAlert` (aktualizacja pola `is_acknowledged` w `temperature_logs`).

2. **State Management (`MonitoringProvider`)**:
    - Udostępnia `activeSensorsProvider` (lista sensorów w strefie).
    - Udostępnia `latestMeasurementsProvider` (mapa `sensor_id -> Measurement`).
    - Oblicza statusy alarmowe w czasie rzeczywistym.

3. **UI Components**:
    - `TemperatureDashboardScreen`: Główny widok z kafelkami sensorów.
    - `SensorChartScreen`: Wykres temperatury (biblioteka `fl_chart`) z przedziałami czasowymi (1h, 6h, 12h, 24h).
    - `AlarmsPanelScreen`: Lista aktywnych i historycznych alarmów z funkcją potwierdzania (Long Press).

### 6.3 Decyzje Projektowe

- **Glove-Friendly UX:** Wszystkie interakcje krytyczne (potwierdzenie alarmu) wymagają przytrzymania przycisku przez 1 sekundę (`HaccpLongPressButton`) co zapobiega przypadkowym kliknięciom w rękawicach.
- **Dark Mode Only:** Interfejs jest zoptymalizowany pod kątem pracy w ciemnych pomieszczeniach (chłodnie), używając ciemnego tła i jaskrawych kolorów akcentowych (zielony/czerwony) dla szybkiej identyfikacji statusu.

### 15.3 Troubleshooting M02 (Missing Sensors)

W przypadku błędu "Brak aktywnych sensorów w tej strefie", mimo że dane są w bazie:

1. **Problem: RLS Role Mismatch**
   - **Przyczyna:** Aplikacja używa `signInAnonymously()`. Jeśli anonimowe logowanie jest wyłączone w Supabase, klient używa roli `anon`. Jeśli polityka RLS zezwala tylko `authenticated`, dane są blokowane.
   - **Rozwiązanie:** Skrypt `27_fix_rls_anon.sql` nadaje uprawnienia obu rolom (`anon`, `authenticated`).

2. **Problem: Zone ID Mismatch**
   - **Przyczyna:** Sensory są przypisane do strefy o nazwie "Kuchnia", ale z innym ID niż ta, do której ma dostęp aktualny pracownik.
   - **Rozwiązanie:** Skrypty diagnostyczne `23_diagnostic_mismatch.sql` oraz naprawczy `25_fix_force_kuchnia.sql`, który precyzyjnie paruje sensory z ID strefy zalogowanego użytkownika.

---

## 16. Pipeline Chłodzenia → Baza Danych → Raporty (Plan Implementacji)

Sekcja opisuje pełny przepływ danych od formularza M03 przez bazę po generowanie raportu CCP-3 w M06.

### 16.1 Architektura Przepływu (Data Flow)

```
┌─────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│  FoodCoolingForm     │     │    Supabase DB        │     │   Raport CCP-3       │
│  (M03)               │     │                      │     │   (M06)              │
│                     │     │                      │     │                      │
│ DynamicFormRenderer  │     │  ┌────────────────┐  │     │  ReportsRepository   │
│ ↓                   │────▶│  │  haccp_logs     │  │────▶│  .getCoolingLogs()   │
│ GmpProvider          │     │  │  category='gmp' │  │     │  ↓                  │
│ ↓                   │     │  │  form_id=       │  │     │  PdfService          │
│ GmpRepository        │     │  │    'food_cooling│  │     │  .generateCcp3Report │
│ .insertLog()         │     │  │    _daily'      │  │     │  ↓                  │
│                     │     │  │  data=JSONB     │  │     │  Ccp3PreviewScreen   │
└─────────────────────┘     │  └────────────────┘  │     └──────────────────────┘
                            │                      │
                            │  ┌────────────────┐  │
                            │  │  products       │  │
                            │  │  name, type     │  │
                            │  └────────────────┘  │
                            └──────────────────────┘
```

### 16.2 Znane Bugi (Do Naprawy Przed Sprintem 1)

| # | Bug | Plik | Opis |
|---|-----|------|------|
| 1 | **form_id mismatch** | `food_cooling_form_screen.dart` L20 vs `reports_repository.dart` L27 | Formularz zapisuje `form_id='food_cooling_daily'`, ale `ReportsRepository.getCoolingLogs()` filtruje po `form_id='food_cooling'`. **Dane nigdy nie są znajdowane w raporcie.** |
| 2 | **Brak widgetu Text** | `dynamic_form_renderer.dart` | `HaccpFieldType.text` (pole "Uwagi") wpada do `default:` i renderuje placeholder zamiast funkcjonalnego pola tekstowego. |
| 3 | **Duplikat @riverpod** | `gmp_provider.dart` L43-44 | Podwójna adnotacja `@riverpod` nad `gmpHistory`. |
| 4 | **Brak trasy CCP-3** | `app_router.dart` | Trasa `/reports/preview/ccp3` prawdopodobnie nie jest zarejestrowana w GoRouter, co powoduje błąd nawigacji po zapisaniu formularza. |

### 16.3 Struktura JSONB w `haccp_logs.data`

Po zapisaniu formularza Chłodzenia, kolumna `data` (JSONB) zawiera:

```json
{
  "product_name": "Pierogi Ruskie",
  "prep_date": "2026-02-19",
  "start_temp": 65,
  "start_time": "14:00",
  "temp_2h": 20,
  "end_temp": 4,
  "end_time": "16:15",
  "comments": "Brak uwag"
}
```

Moduł raportów (`PdfService._generateCcp3PdfIsolate`) odczytuje te pola z mapy `data` i mapuje je na kolumny tabeli PDF.

---

### 16.4 Plan Sprintów (Dla Junior Developera)

#### Sprint 1: Naprawa Krytycznych Bugów (Bug Fixes)

**Cel:** Formularz zapisuje dane poprawnie → raport znajduje te dane → nawigacja działa.

**Zadania:**

1. **Ujednolicenie `form_id`**
   - W pliku `food_cooling_form_screen.dart` zmień `const String formId = 'food_cooling_daily'` na `'food_cooling'`.
   - **LUB** w pliku `reports_repository.dart` zmień `.eq('form_id', 'food_cooling')` na `.eq('form_id', 'food_cooling_daily')`.
   - Wybierz **jedną** wersję i użyj jej wszędzie. Zalecane: `'food_cooling'` (krótsze, spójne z konwencją).

2. **Usunięcie duplikatu `@riverpod`**
   - W pliku `gmp_provider.dart` linia 43-44: usuń jedną z dwóch adnotacji `@riverpod`.
   - Uruchom `dart run build_runner build --delete-conflicting-outputs` po edycji.

3. **Dodanie trasy CCP-3 do GoRouter**
   - W pliku `app_router.dart` dodaj trasę:

     ```
     /reports/preview/ccp3?date=...
     ```

   - Parametr `date` (queryParam) parsuj na `DateTime` i przekaż do `Ccp3PreviewScreen(date: ...)`.

4. **Weryfikacja:**
   - Wypełnij formularz → Zapisz → Sprawdź w Supabase Dashboard, że wiersz pojawił się w `haccp_logs` z poprawnym `form_id`.
   - Sprawdź, że nawigacja do podglądu CCP-3 działa (nie pokazuje białego/pustego ekranu lub 404).

---

#### Sprint 2: Implementacja Brakującego Widgetu Text

**Cel:** Pole "Uwagi / Działania korygujące" w formularzu jest w pełni funkcjonalne.

**Zadania:**

1. **Stwórz widget `HaccpTextInput`**
   - Plik: `lib/features/shared/widgets/dynamic_form/haccp_text_input.dart`.
   - Widget typu `StatelessWidget` wyświetlający `TextField` z ciemnym tłem (`HaccpDesignTokens.surface`).
   - Parametry: `String? value`, `ValueChanged<String> onChanged`, `String? hintText`.
   - **Glove-Friendly:** Min. height 56dp, duży fontSize (16), jasny placeholder.

2. **Dodaj case do `DynamicFormRenderer`**
   - W `_buildField()`, przed `default:`, dodaj:

     ```
     case HaccpFieldType.text:
       return HaccpTextInput(...)
     ```

   - Import nowego pliku.

3. **Weryfikacja:**
   - Otwórz formularz Chłodzenia → Pole "Uwagi" powinno być edytowalne (klawiatura pojawia się przy kliknięciu).
   - Zapisz formularz z wypełnionym polem "Uwagi" → Sprawdź w Supabase, że `data.comments` ma wartość.

---

#### Sprint 3: Integracja Raportu z Danymi z Bazy

**Cel:** Po zapisaniu formularza użytkownik automatycznie widzi wygenerowany raport PDF z danymi.

**Zadania:**

1. **Poprawka `_handleSubmit` w `food_cooling_form_screen.dart`**
   - Usuń blok komentarzy TODO (linie ~70-127).
   - Po `HaccpSuccessOverlay.show(context)`:
     - Parsuj `dateStr` z `state.values['prep_date']`.
     - Nawiguj: `context.push('/reports/preview/ccp3?date=$dateStr')`.

2. **Sprawdź `Ccp3PreviewScreen`**
   - `ccp3ReportProvider` pobiera logi za dany dzień via `repo.getCoolingLogs(date)`.
   - Upewnij się, że `getCoolingLogs` filtruje po `form_id` **spójnym** z wartością ustaloną w Sprincie 1.
   - Zweryfikuj, że `PdfService.generateCcp3Report` poprawnie mapuje pola JSONB (patrz sekcja 16.3).

3. **Obsługa pustych danych**
   - Jeśli `logs` jest puste (np. brak danych za dany dzień), wyświetl komunikat zamiast pustego PDF.
   - W `Ccp3PreviewScreen`: sprawdź `logs.isEmpty` i pokaż `HaccpEmptyState`.

4. **Weryfikacja:**
   - Wypełnij formularz → ZAPISZ → powinien pojawić się podgląd PDF z danymi z formularza.
   - Sprawdź, że tabela w PDF zawiera poprawne wartości (produkt, temperatury, godziny).

---

#### Sprint 4: Trwałość Raportów (Persistence)

**Cel:** Wygenerowane raporty są archiwizowane w chmurze i dostępne do przeglądania / pobrania.

**Zadania:**

1. **Uruchom SQL migrację `31_create_generated_reports.sql`** (jeśli jeszcze nie uruchomiona)
   - Tabela `generated_reports`: `id`, `venue_id`, `report_type`, `generation_date`, `storage_path`, `created_by`, `created_at`.
   - Bucket `reports` w Supabase Storage.

2. **Dodaj przycisk "Zapisz do chmury" w `Ccp3PreviewScreen`**
   - Po wygenerowaniu PDF (`pdfAsync.data`):
     - Upload `Uint8List` do Supabase Storage: `reports/ccp3/YYYY-MM-DD_HHmmss.pdf`.
     - Insert do `generated_reports` z metadanymi.
   - Pokaż `SnackBar` sukcesu.

3. **Lista zapisanych raportów w module M06**
   - W istniejącym `ReportsPanelScreen` dodaj sekcję "Archiwum CCP-3".
   - Pobierz z `generated_reports` WHERE `report_type = 'ccp3'`.
   - Wyświetl listę z datą i przyciskiem "Otwórz" (pobiera z Storage i otwiera w viewerze).

4. **Weryfikacja:**
   - Zapisz PDF → sprawdź w Supabase Storage, że plik istnieje.
   - Otwórz Archiwum → kliknij na raport → powinien się otworzyć ten sam PDF.

---

#### Sprint 5: Produkty z Bazy Danych (Products Table)

**Cel:** Dropdown produktów w formularzu ładuje opcje z bazy danych zamiast hardcodowanych list.

**Zadania:**

1. **Uruchom SQL migrację `33_create_products_table.sql`** w Supabase Dashboard
   - Tworzy tabelę `products` z kolumnami `id`, `name`, `type`, `created_at`.
   - Dodaje seed data (Pierogi, Gołąbki, Bigos).

2. **Sprawdź działanie `HaccpDropdown`**
   - Widget jest już zaimplementowany (`haccp_dropdown.dart`).
   - Konfiguracja formularza (`form_definitions.dart`) wskazuje na `source: 'products_table'`, `type: 'cooling'`.
   - `ProductsRepository` (`products_repository.dart`) pobiera dane z tabeli.
   - **TEST:** Otwórz formularz → dropdown powinien załadować produkty z Supabase (nie z hardcodowanej listy).

3. **Dodaj ekran "Zarządzanie Produktami" (opcjonalnie)**
   - Prosty CRUD screen dostępny z Ustawień (M08) dla roli `manager`/`owner`.
   - Lista produktów z przyciskiem "Dodaj nowy".

4. **Weryfikacja:**
   - Dodaj nowy produkt w Supabase (np. "Pierogi z Serem") → otwórz formularz → nowy produkt powinien pojawić się w dropdown.

---

### 16.5 Kolejność Priorytetów

| # | Sprint | Priorytet | Uzasadnienie |
|---|--------|-----------|-------------|
| 1 | Bug Fixes | 🔴 KRYTYCZNY | Bez tego dane nie docierają do raportu |
| 2 | Widget Text | 🟠 WYSOKI | Pole "Uwagi" jest wymagane w procesie HACCP |
| 3 | Integracja Raportu | 🟠 WYSOKI | Core feature: automatyczny raport po zapisie |
| 4 | Persistence | 🟡 ŚREDNI | Archiwizacja dla audytu |
| 5 | Produkty DB | 🟢 NISKI | Już częściowo działa (migracja do uruchomienia) |

---
Autor: Antigravity (AI Agent)
Data wersji: 2026-02-19 (M03→M06 Pipeline Plan & Form Improvements)
