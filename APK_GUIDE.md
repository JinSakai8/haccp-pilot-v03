# Przewodnik Instalacji (APK Release)

Ten dokument opisuje krok po kroku, jak przygotować plik `.apk` do instalacji na tabletach w kuchni.

## 1. Wymagania Wstępne

- Zainstalowany `Flutter SDK`
- Zainstalowana `Java` (JDK)
- Android Studio (opcjonalne, ale zalecane dla sterowników USB)

## 2. Czyszczenie Projektu

Zawsze warto wyczyścić stare buildy przed generowaniem wersji produkcyjnej, aby uniknąć błędów cache.

```bash
flutter clean
flutter pub get
```

## 3. Budowanie APK (Release Mode)

Ta komenda stworzy zoptymalizowaną wersję aplikacji ("fat APK" działającą na wszystkich architekturach procesorów: ARM, ARM64, x86).

```bash
flutter build apk --release
```

Jeśli potrzebujesz wersji tylko na konkretną architekturę (np. nowoczesne tablety ARM64), co zmniejszy rozmiar pliku o połowę:

```bash
flutter build apk --release --target-platform android-arm64
```

## 4. Lokalizacja Pliku

Po udanym buildzie, plik znajdziesz tutaj:

`[Katalog Projektu]\build\app\outputs\flutter-apk\app-release.apk`

## 5. Instalacja na Tablecie

1. Podłącz tablet kablem USB do komputera.
2. Skopiuj plik `app-release.apk` do pamięci tabletu (np. do folderu `Download`).
3. Na tablecie otwórz Menedżer Plików, wejdź w `Download` i kliknij plik `.apk`.
4. Zaakceptuj instalację z "Nieznanych źródeł" jeśli system o to poprosi.

## 6. Wersja "Debug" (Dla Testerów)

Jeśli chcesz zainstalować aplikację bezpośrednio z komputera na podłączony tablet, użyj:

```bash
flutter run --release
```

To zainstaluje i uruchomi wersję release na podłączonym urządzeniu.

---
**Uwaga:** Pamiętaj o ustawieniu kluczy API (Supabase, Google Drive) w pliku `.env` lub bezpośrednio w kodzie (jeśli budujesz bez pliku .env w assets), choć obecna konfiguracja `flutter_dotenv` wymaga pliku `.env` w assets. Upewnij się, że plik ten jest obecny w buildzie.
