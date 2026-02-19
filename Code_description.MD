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
  - CCP-3 (Chłodzenie): Pobiera logi z `haccp_logs`, generuje PDF (pixel-perfect z oryginałem).
  - Temperatury: Agregacja pomiarów (Min/Max/Avg) -> HTML -> PDF.
- **Persistence (Trwałość):**
  - Każdy wygenerowany raport jest automatycznie:
        1. Wysyłany do Supabase Storage (`reports/`).
        2. Rejestrowany w tabeli `generated_reports`.
- **Historia:** Ekran "Archiwum" (`SavedReportsScreen`) pozwala przeglądać i pobierać wcześniejsze raporty bez konieczności ich regenerowania.

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
