# Code Description: HACCP Pilot v04.0 (Live)

Dokumentacja techniczna projektu HACCP Pilot. Opisuje architekturę, strukturę bazy danych oraz logikę poszczególnych modułów. Służy jako "mapa" dla deweloperów.

---

## 1. Filozofia Projektu

- **Glove-Friendly UX:** Wszystkie elementy interaktywne muszą mieć min. **60x60dp**. Unikamy klawiatury systemowej (korzystamy z `HaccpNumPad` lub gotowych opcji).
- **Dark Mode Only:** Aplikacja działa tylko w trybie ciemnym (kuchennym).
- **Offline-First:** Dane są zbierane lokalnie, a synchronizacja następuje przy dostępności sieci.
- **Bezpieczeństwo:** Rygorystyczne zasady RLS i brak przechowywania wrażliwych danych (hash PIN) na kliencie w sposób jawny.

## 2. Struktura Folderów (`lib/`)

Projekt podzielony jest na **Features** (funkcjonalności) i **Core** (wspólne utilities).

```
lib/
├── core/                  # Fundamenty aplikacji
│   ├── config/            # Env, stałe konfiguracyjne
│   ├── constants/         # Design Tokens (kolory, wymiary)
│   ├── router/            # GoRouter (nawigacja)
│   ├── services/          # Serwisy (PDF, Drive, Storage)
│   ├── theme/             # Motyw Fluttera (Dark Theme)
│   └── widgets/           # Globalne widgety (TopBar, Tile)
│
├── features/              # Moduły biznesowe (M01, M02, ...)
│   ├── m01_auth/          # Logowanie (PIN Pad)
│   ├── m02_monitoring/    # IoT (Dashboard temperatur)
│   ├── m03_gmp/           # Procesy produkcyjne (Formularze)
│   ├── m04_ghp/           # Higiena (Checklisty)
│   ├── m05_waste/         # Odpady (Kamera)
│   ├── m06_reports/       # Raportowanie (Generowanie PDF, Archiwum)
│   ├── m07_hr/            # Kadry (Pracownicy, Sanepid)
│   ├── m08_settings/      # Ustawienia (Lokal, Produkty)
│   └── shared/            # Moduł Wspólny (Silnik Formularzy, Repozytoria Produktów)
```

## 3. Architektura Systemu

Stosujemy architekturę **Layered Architecture** z **Riverpod** do zarządzania stanem.

1. **Repository (`repositories/`)**:
    - Jedyny punkt styku z Supabase.
    - Odpowiada za CRUD i logikę biznesową danych.
    - *Zasada:* Jedno repozytorium na domenę (np. `ProductsRepository`, `GmpRepository`).

2. **Provider (`providers/`)**:
    - Zarządza stanem aplikacji (`AsyncNotifier`, `FutureProvider`).
    - Pośredniczy między UI a Repozytorium.
    - Obsługuje cache'owanie i odświeżanie danych.

3. **Screen/Widget**:
    - Warstwa prezentacji.
    - Nasłuchuje zmian w Providerach (`ref.watch`).
    - Nie wykonuje bezpośrednich zapytań do bazy.

---

## 4. Baza Danych (Supabase)

System opiera się na relacyjnej bazie PostgreSQL. Poniżej aktualny schemat tabel.

### 4.1 Główne Tabele

| Tabela | Opis | Kluczowe Kolumny |
|:---|:---|:---|
| **`venues`** | Lokale gastronomiczne | `id`, `name`, `address`, `nip`, `logo_url` |
| **`employees`** | Pracownicy | `id`, `venue_id`, `full_name`, `pin_hash`, `role` (owner/manager/cook), `sanepid_expiry` |
| **`zones`** | Strefy w lokalu (np. Kuchnia) | `id`, `venue_id`, `name` |
| **`employee_zones`** | Przypisanie pracownika do strefy | `employee_id`, `zone_id` |
| **`products`** | Produkty/Potrawy (Menu) | `id`, `venue_id` (nullable), `name`, `type` (cooling/roasting), `created_at` |
| **`haccp_logs`** | Logi procesów (GMP/GHP) | `id`, `venue_id`, `form_id`, `data` (JSONB), `created_by`, `created_at` |
| **`temperature_logs`** | Pomiary IoT | `id`, `sensor_id`, `temperature`, `timestamp` |
| **`sensors`** | Urządzenia IoT | `id`, `zone_id`, `name`, `mac_address` |
| **`waste_records`** | Rejestr odpadów | `id`, `venue_id`, `waste_type`, `mass_kg`, `photo_url` |
| **`generated_reports`** | Archiwum PDF | `id`, `venue_id`, `report_type`, `generation_date`, `storage_path` |

### 4.2 Kluczowe Relacje i Bezpieczeństwo (RLS)

- **Multi-tenancy:** Większość tabel posiada kolumnę `venue_id`. RLS zapewnia, że pracownik widzi dane tylko ze swojego lokalu.
- **Produkty:** Tabela `products` obsługuje produkty globalne (`venue_id` IS NULL) dostępne dla wszystkich oraz lokalne (`venue_id` = X) widoczne tylko w danym lokalu.
- **Logowanie:** Wykorzystuje mechanizm **RPC** (`login_with_pin`) do bezpiecznej weryfikacji hasha PIN po stronie serwera, omijając ograniczenia RLS dla użytkownika anonimowego.

---

## 5. Opis Modułów

### M01: Autoryzacja

- **Ekran:** `PinPadScreen`.
- **Logika:** Weryfikacja PIN -> Pobranie Profilu Pracownika -> Pobranie Stref.
- **Bezpieczeństwo:** Blokada czasowa po 5 nieudanych próbach (Brute-force protection).

### M02: Monitoring IoT

- **Cel:** Podgląd temperatur w czasie rzeczywistym.
- **Logika:** Subskrypcja `Supabase Realtime` na tabelę `temperature_logs`.
- **Alerty:** Lokalne wykrywanie przekroczeń progów (zdefiniowanych w ustawieniach). Kafelki zmieniają kolor (Zielony/Pomarańczowy/Czerwony).

### M03: Procesy GMP (Formularze Dynamiczne)

- **Cel:** Rejestracja procesów (Chłodzenie, Obróbka, Dostawy).
- **Silnik:** `DynamicFormRenderer` generuje UI na podstawie definicji JSON (`FormDefinition`).
- **Produkty:** Pola typu "produkt" pobierają listę z `ProductsRepository` (tabela `products`), uwzględniając menu lokalu.
- **Zapis:** Dane trafiają do `haccp_logs` jako JSONB.
- **Integracja:** Historia GMP (`GmpHistoryScreen`) umożliwia podgląd wygenerowanego raportu PDF (`PdfPreviewScreen`).

### M04: Higiena GHP

- **Cel:** Listy kontrolne (Sprzątanie, Higiena osobista).
- **UI:** Interfejs oparty na dużych przyciskach TAK/NIE (`HaccpToggle`).
- **Logika:** Zapis do `haccp_logs` z `category='ghp'`.

### M05: Odpady (Waste)

- **Cel:** Rejestracja utylizacji żywności.
- **Kamera:** Własna implementacja `HaccpCameraScreen` (duży spust migawki, brak UI systemowego).
- **Storage:** Zdjęcia są kompresowane i wysyłane do bucketu `waste-docs`. URL zapisywany w bazie.

### M06: Raportowanie (Reports)

- **Generowanie:**
  - **CCP-3 (Chłodzenie):** Pobiera logi z `haccp_logs` (agregacja dzienna), generuje PDF (pixel-perfect z oryginałem). Obsługuje limity (20°C/2h, 30°C krytyczne) i kolorowanie niezgodności.
  - **Temperatury:** Agregacja pomiarów (Min/Max/Avg) -> HTML -> PDF.
- **Persistence (Trwałość):**
  - Każdy wygenerowany raport jest automatycznie:
        1. Wysyłany do Supabase Storage (`reports/`).
        2. Rejestrowany w tabeli `generated_reports` (metadata).
- **Historia:** Ekran "Archiwum" (`SavedReportsScreen`) pozwala przeglądać i pobierać wcześniejsze raporty.
- **Podgląd:**
  - `Ccp3PreviewScreen` wyświetla PDF z pamięci (`SfPdfViewer.memory`).
  - Posiada fallback do pobierania pliku (`file_opener_web`) w razie problemów z renderowaniem w przeglądarce.

### M07: Kadry (HR)

- **Dostęp:** Tylko dla `manager` / `owner`.
- **Funkcje:** Zarządzanie pracownikami, przypisywanie stref, monitoring dat ważności badań Sanepid.

### M08: Ustawienia (Settings)

- **Konfiguracja Lokalu:** Nazwa, Adres, NIP, Logo (upload).
- **Zarządzanie Produktami:** CRUD dla tabeli `products`. Umożliwia dodawanie własnych pozycji do list wyboru w formularzach GMP.
- **Konfiguracja IoT:** Interwały pomiarowe, progi alarmowe.

---

## 6. Serwisy Zewnętrzne i Integracje

1. **PDF Service (`PdfService`)**:
    - Generuje dokumenty PDF (Syncfusion).
    - Obsługuje tabele, nagłówki z logo lokalu, łączenie komórek.

2. **Supabase Storage**:
    - Buckety: `waste-docs` (zdjęcia odpadów), `reports` (archiwalne PDF), `branding` (logo lokali).

3. **Google Drive Integration**:
    - Opcjonalny eksport raportów na dysk Google (Service Account).

---

## 7. Wdrażanie (Build & Deploy)

Aplikacja jest budowana jako **Flutter Web** (PWA).

- **Komenda:** `flutter build web --release --no-tree-shake-icons`.
- **Hosting:** Vercel (automatyczny deploy z GitHub).
- **Konfiguracja:** Zmienne środowiskowe (Supabase URL/Key) są wstrzykiwane podczas builda (`--dart-define`).

---

## 8. Aktualizacja kodu M02 (2026-02-23): Tabela 7 dni + edycja temperatury

### 8.1 Zakres UI (Sensor Chart)

- `SensorChartScreen` ma 4 tryby:
  - `24h`
  - `7 dni`
  - `30 dni`
  - `Tabela 7 dni`
- W trybie tabeli pokazujemy kolumny:
  - data
  - godzina
  - temperatura
  - alert
  - status potwierdzenia
  - akcja

### 8.2 Read path i logika aplikacyjna

- Repozytorium:
  - `MeasurementsRepository.getSevenDayTable(sensorId)`
- Provider:
  - `sensorSevenDayTableProvider`
- Akcja edycji:
  - `TemperatureLogEditAction.editTemperatureLog(...)`
  - invalidacja po zapisie:
    - `sensorSevenDayTableProvider`
    - `sensorHistoryProvider` dla zakresow `24h/7d/30d`

### 8.3 Reguly edycji po stronie klienta

- Walidacje:
  - liczba dziesietna
  - maksymalnie 2 miejsca po przecinku
  - zakres `-50..150`
- Bramka uprawnien UI:
  - aktywna edycja tylko dla `manager`/`owner`
  - `cook`/`cleaner` -> readonly
- Bramka czasu:
  - edycja tylko dla rekordow `>= now() - 7 dni`

### 8.4 Integracja z DB (RPC zamiast direct update)

- Aplikacja korzysta z RPC:
  - `update_temperature_log_value` (edycja)
  - `acknowledge_temperature_alert` (ACK alertu)
- Brak bezposredniego `.update()` na `temperature_logs` w kodzie klienta.

### 8.5 Testy i walidacja

- Dodane testy widgetowe M02:
  - scenariusz graniczny `6d23h` vs `7d+1m`
  - scenariusz roli `cook` (readonly)
- Wynik suite po zmianach (2026-02-23):
  - `flutter test` -> **34 passed, 1 skipped, 0 failed**

---

## 9. Aktualizacja kodu M02 (2026-02-23): Alarm Panel Refactor

### 9.1 Nowy model widoku alarmu

- Dodany DTO:
  - `lib/features/m02_monitoring/models/alarm_list_item.dart`
- UI panelu alarmow nie renderuje juz surowego `TemperatureLog`, tylko read-model `AlarmListItem`.

### 9.2 Zmiana read path alarmow

- Repozytorium:
  - `MeasurementsRepository.getAlerts(...)` korzysta z RPC `get_temperature_alarms(...)`.
- Provider:
  - `alarmsProvider(zoneId, activeOnly)` zwraca `List<AlarmListItem>`.
- Usuniety zostal dwuetapowy flow `alarms + sensors` po stronie UI.

### 9.3 Refactor UI ekranu alarmow

- Zmieniony plik:
  - `lib/features/m02_monitoring/screens/alarms_panel_screen.dart`
- Wprowadzone elementy:
  - czytelne karty alarmow (sensor, temperatura 24sp, czas trwania, status)
  - taby: `AKTYWNE` / `HISTORIA`
  - `HaccpEmptyState` per tab
  - loading per rekord podczas ACK
  - blokada duplikacji ACK
- ACK realizowany jest przez `HaccpLongPressButton` (1s), zgodnie z architektura glove-friendly.

### 9.4 Usprawnienia komponentu long press

- Zmieniony plik:
  - `lib/core/widgets/haccp_long_press_button.dart`
- Dodano zabezpieczenie przed overflow tekstu (`Expanded + ellipsis`) dla waskich layoutow.

### 9.5 Testy

- Dodane testy widgetowe:
  - `test/features/m02_monitoring/alarms_panel_screen_test.dart`
- Zakres:
  - render aktywnej karty
  - render historii bez przycisku ACK
  - brak overflow dla szerokosci `360px`

---

## 10. Lokalne Narzedzia

- Flutter SDK (Windows): C:\scr\flutter\bin
- Uzywaj tej sciezki jako domyslnej lokalizacji Flutter CLI w tym projekcie.


---

## 11. Aktualizacja kodu M07 (2026-02-24): Stabilizacja HR

### 11.1 Zakres zmian

Wdrozono pakiet `Krytyczne + Stabilizacja` dla modulu HR:
- naprawa kontraktu dodawania pracownika,
- stabilizacja flow `AddEmployee`,
- przejscie zmiany PIN na RPC,
- odchudzenie layoutu dashboardu HR.

### 11.2 Zmiany w warstwie repository

Plik: `lib/features/m07_hr/repositories/hr_repository.dart`
- `createEmployee(...)` nadal korzysta z RPC `create_employee`,
- dodano mapowanie bledow domenowych M07 (`M07_PIN_DUPLICATE`, `M07_ZONE_REQUIRED`, `M07_ZONE_NOT_FOUND`, `M07_ZONE_MULTI_VENUE`, `M07_EMPLOYEE_NOT_FOUND`, `M07_PIN_REQUIRED`),
- `updatePin(...)` przelaczono z direct update tabeli `employees` na RPC `update_employee_pin`.

### 11.3 Zmiany w UI M07

Plik: `lib/features/m07_hr/screens/add_employee_screen.dart`
- blokada duplikacji submit podczas `loading`,
- czytelne komunikaty po bledach RPC,
- filtrowanie stref do biezacego kontekstu lokalu (`currentZoneProvider`),
- poprawa stabilnosci inputu PIN i walidacji.

Plik: `lib/features/m07_hr/screens/hr_dashboard_screen.dart`
- zastapiono duze karty alertow kompaktowym ukladem:
  - 3 karty statusu (przeterminowane, wygasaja <=30d, wazne),
  - krotkie listy alertow z CTA `Zobacz wszystkie`,
  - szybkie akcje `Lista` i `Dodaj`.

### 11.4 Zmiany pomocnicze i testy

Nowy plik: `lib/features/m07_hr/utils/hr_alerts_snapshot.dart`
- wydzielenie klasyfikacji pracownikow wg dat sanepidu (expired / expiring / valid).

Nowy test: `test/features/m07_hr/hr_alerts_snapshot_test.dart`
- test klasyfikacji alertow,
- test granicy `today + 30 dni`.

### 11.5 Efekt funkcjonalny

Po zmianach nowy pracownik tworzony przez M07 ma poprawna sciezke do dalszego flow kiosk/auth, a panel HR nie jest blokowany przez rozciagniete kafelki.

---

## 12. Aktualizacja kodu M08 (2026-02-24): Settings Recovery + UX Domkniecie

### 12.1 Routing i autoryzacja

Plik: `lib/core/router/app_router.dart`
- Guard roli rozszerzony o M08:
  - `/settings`
  - `/settings/products`
- Dostep tylko dla `manager` / `owner` (spojnie z M07 HR).

### 12.2 Stabilizacja `GlobalSettingsScreen`

Plik: `lib/features/m08_settings/screens/global_settings_screen.dart`
- Usunieto ryzyko nieskonczonego loadera:
  - zrodlo `venueId` oparte o `currentZoneProvider`.
- Dodany jawny stan bledu przy braku aktywnej strefy (CTA do `/zone-select` i `/hub`).
- Zapis ustawien:
  - sukces przez `HaccpSuccessOverlay`,
  - mapowanie bledow DB/RLS na komunikaty domenowe,
  - walidacja NIP (`10` cyfr) po stronie UI.
- Sekcja `System` zostala oznaczona jako lokalna (bez persystencji DB).

### 12.3 Domkniecie `ManageProductsScreen`

Plik: `lib/features/m08_settings/screens/manage_products_screen.dart`
- CRUD oparty o aktualny kontekst lokalu (`currentZoneProvider`).
- Dodana walidacja nazwy produktu i deduplikacja w kategorii.
- Dodany czytelny pusty stan przez `HaccpEmptyState`.
- Ujednolicone mapowanie bledow (RLS/constraint) w SnackBar.

### 12.4 `ProductsRepository` (usuniecie fallbackow)

Plik: `lib/features/shared/repositories/products_repository.dart`
- Usuniete fallbackowe dane awaryjne maskujace problemy runtime.
- `getProducts(...)` zwraca realny wynik DB lub blad (z logiem `debugPrint`).
- `productsProvider` korzysta z `currentZoneProvider` zamiast dodatkowych zapytan o strefy.

### 12.5 Testy M08

Nowe/uzupelnione testy:
- `test/features/m08_settings/global_settings_screen_test.dart`
  - scenariusze braku aktywnej strefy + nawigacja CTA.
- `test/features/m08_settings/m08_sprint3_test.dart`
  - mapowanie bledow settings,
  - empty state produktow.

Wyniki (2026-02-24):
- `flutter test test/features/m08_settings --reporter compact` -> PASS
- `flutter test --reporter compact` -> PASS (`43 passed, 1 skipped, 0 failed`)
