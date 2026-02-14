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
Autor: Antigravity (AI Agent)
Data wersji: 2026-02-14
