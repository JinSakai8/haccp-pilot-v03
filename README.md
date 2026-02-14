# HACCP Pilot v03

**HACCP Pilot** to nowoczesna, "Glove-Friendly" aplikacja Flutterowa do cyfryzacji procesów HACCP w gastronomii. Zaprojektowana tak, aby działała w trudnych warunkach kuchennych (tryb ciemny, duże przyciski, obsługa offline).

## Kluczowe Funkcjonalności

### 1. Bezpieczeństwo i Logowanie (M01)

- Logowanie 4-cyfrowym kodem PIN.
- Role: Owner, Manager, Pracownik (Cook/Driver).
- Haszowanie PIN (SHA-256).

### 2. Monitoring Temperatur (M02)

- Integracja z sensorami IoT (Efento/BleBox).
- Dashboard z kafelkami zmieniającymi kolor w zależności od odchyłek norm.

### 3. Procesy Produkcyjne (M03 GMP / M04 GHP)

- Dynamiczny silnik formularzy (JSON-driven UI).
- Obsługa procesów: Dostawy, Obróbka Termiczna, Chłodzenie, Sprzątanie.
- Walidacja "Non-Blocking" (wymuszenie komentarza przy odchyłce).

### 4. Gospodarka Odpadami (M05)

- Rejestracja odpadów UPPZ.
- **Kamera Glove-Friendly**: Własny interfejs aparatu z gigantycznym spustem migawki.
- Automatyczny upload zdjęć do chmury.

### 5. Raportowanie (M06)

- Generowanie raportów PDF z tabelami i zdjęciami.
- Automatyczna archiwizacja na Google Drive.
- Obsługa logo lokalu w nagłówkach.

### 6. HR & Personel (M07)

- Ewidencja pracowników i ważności badań Sanepid.
- Alerty o wygasających badaniach.

### 7. Ustawienia i Offline (M08)

- Zarządzanie danymi lokalu (Nazwa, NIP, Logo).
- Pełna obsługa trybu offline (wskaźniki braku sieci, lokalny zapis - *w przygotowaniu do pełnej synchronizacji*).

## Technologie

- **Frontend**: Flutter (Mobile/Tablet).
- **Backend & Auth**: Supabase.
- **State Management**: Riverpod.
- **Nawigacja**: GoRouter.
- **PDF**: Syncfusion Flutter PDF.

## Instalacja

1. Sklonuj repozytorium.
2. Stwórz plik `.env` i dodaj:

   ```
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   DRIVE_FOLDER_ID=...
   ```

3. Dodaj `assets/credentials.json` (Service Account Google).
4. Uruchom:

   ```bash
   flutter pub get
   flutter run
   ```

## Autor

Projekt rozwijany przez **FlowsForge** (Antigravity AI Agent).
