# Directive 02: Core Infrastructure (Riverpod, GoRouter, Supabase)

## Cel

Przekształcenie statycznych ekranów Google Stitch w dynamiczną aplikację Flutter. Inicjalizacja zarządzania stanem, routingu oraz połączenia z bazą danych, zgodnie z załozonym architektonicznym Dark Mode.

## Zadania do wykonania (Execution)

1. **Zależności (`pubspec.yaml`):** - Dodaj: `flutter_riverpod`, `go_router`, `supabase_flutter`, `flutter_dotenv`.
   - Wykonaj `flutter pub get`.
2. **Supabase & Env Init (`main.dart`):**
   - Zmodyfikuj `main()`, aby ładował `.env` oraz inicjalizował `Supabase.initialize()`.
   - Owiń główny widget aplikacji w `ProviderScope` (dla Riverpoda).
3. **Konfiguracja Motywu (Dark Mode):**
   - W pliku odpowiedzialnym za motyw (np. `app_theme.dart`), ustaw `ThemeData.dark()`. Tło aplikacji ma używać ciemnych odcieni (Onyx/Charcoal), dostosowując teksty na białe/jasne, zgodnie z `UI_description.md`.
4. **Routing (`core/routing/app_router.dart`):**
   - Skonfiguruj `GoRouter`.
   - Podepnij pierwsze wygenerowane ekrany ze Stitcha: Splash Screen (1.1) -> PIN Pad (1.2) -> Wybór Strefy (1.3) -> Dashboard Hub.
   - *Tymczasowo:* Zezwól na swobodne przechodzenie między tymi ekranami (bez autoryzacji), abyśmy mogli przetestować nawigację.

## Oczekiwany rezultat

Aplikacja kompiluje się bez błędów. Zmienne `.env` są wczytywane, Supabase jest podłączony, a użytkownik widzi ciemny motyw i może przeklikać się przez ekrany logowania aż do Dashboardu.
