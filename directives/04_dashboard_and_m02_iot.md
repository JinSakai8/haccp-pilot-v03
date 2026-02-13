# Directive 04: Dashboard Hub & M02 IoT Foundation

## Cel

Zbudowanie głównego ekranu nawigacyjnego (Dashboard Hub) oraz wdrożenie fundamentów pod moduł M02 (Monitoring Temperatur w czasie rzeczywistym via WebSockets).

## Zadania do wykonania (Execution)

### 1. Baza Danych (M02 Foundation)

Wygeneruj skrypt SQL (do ręcznego wklejenia w Supabase), który utworzy tabele:

- `sensors` (id, name, zone_id, is_active)
- `temperature_logs` (id, sensor_id, temperature_celsius, recorded_at, is_alert)
Włącz RLS i utwórz polityki odczytu/zapisu dla zalogowanych ról.

### 2. Dashboard Hub (UI)

- Zaimplementuj ekran `dashboard_screen.dart`.
- Zbuduj siatkę (Grid) 7 kafelków zgodnie z `UI.md`.
- Każdy kafelek musi mieć min. wymiary 80x80dp (Glove-Friendly), ikonę, czytelny tytuł i reagować na kliknięcie (routing do odpowiednich ścieżek M02-M08, nawet jeśli to na razie puste ekrany).
- Zastosuj `app_theme.dart` (Dark Mode: Onyx/Charcoal).

### 3. Moduł M02 (Realtime Data Layer)

- Utwórz modele `Sensor` i `TemperatureLog`.
- W `lib/features/m02_monitoring/` utwórz `temperature_repository.dart`.
- Zaimplementuj `StreamProvider` (Riverpod), który nasłuchuje zmian w tabeli `temperature_logs` przy użyciu **Supabase Realtime** (`supabase.from('temperature_logs').stream(primaryKey: ['id'])`).

## Oczekiwany rezultat

Po poprawnym zalogowaniu, użytkownik widzi piękny, ciemny Dashboard z 7 dużymi kafelkami. Pod spodem aplikacja ma już gotowy system subskrypcji WebSockets, gotowy do odbierania danych z termometrów Efento.
