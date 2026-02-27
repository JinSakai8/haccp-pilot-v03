# Sprint 1: Formularz UI i Model Danych (M03)

**Cel Sprintu:** Zmiana wyglądu obecnego komponentu dla wariantu Piece/Pieczenie (Ekran 3.2), tak aby obsłużył dodatkowe metadane, nałożone przez wymogi raportowe w Arkuszu CCP-2.

## Działania: UI (Flutter)

- Plik: `lib/features/m03_gmp/screens/meat_roasting_form_screen.dart`
- **Walidacja na 90°C:** Według oryginalnej `UI_description.md` ekran weryfikował jako ostrzeżenie temperaturę wewnętrzną < 75°C. Teraz musi ona ostrzegać < 90°C, ze względu na zmianę specyfikacji (Krytyczna minimalna 90°C na Arkuszu CCP-2).
- **Dodanie HaccpToggle:**
  - Dodaj kontrolkę "Zgodność z ustaleniami" wzorując się na `food_cooling_form_screen.dart`.
  - Powinna składać się z logiki zielony/czerwony dla potwierdzenia (is_compliant = true/false).
- **Dodanie Pola Comment (TextField):**
  - Uwidaczniane pod kontrolką `HaccpToggle` w przypadku zaznaczenia na CZERWONO. Zawiera wpis "Działania korygujące" w celu wpisania co pracownik poczynił (np. "Dopieczenie", "Złomowanie mięsa").
- **Działanie Zapisz:**
  - Mapowanie tych dwóch dodatkowych zmiennych do słownika JSON wysyłanego poprzez funkcję `insertLog` repozytorium `GmpRepository`. Atrybuty w obrębie słownika JSONB `data` w `haccp_logs` polecam nazwać: `is_compliant` (bool) oraz `corrective_actions` (string).

## Działania: Model (Supabase DB)

- Baza danych oraz tabela `haccp_logs` używa kolumn typu JSONB - oznacza to, ze schema BD NIE wymaga w tym przypadku modyfikacji dla dodania poszczególnych zmiennych. Trzeba się tylko upewnić o dobrej implementacji w Riverpod repo z poziomu Fluttera. W formularzu Pieczenia używamy `form_id` o nazwie `meat_roasting`.
- Sprawdź kompatybilność typów wstecznie (stare powiedzmy 3 wpisy z pieczenia nie będą posiadały nowej zmiennej is_compliant). W kodzie, zaimplementować przyzwoity parser fallback, by null potraktować po prostu jako false lub null podczas wyświetlania starych instancji w module z historią.
