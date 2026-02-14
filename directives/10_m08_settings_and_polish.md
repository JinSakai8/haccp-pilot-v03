# Directive 10: Module M08 & Global Polish

## Cel
Finalizacja systemu poprzez dodanie modułu ustawień lokalu oraz ostateczne szlify UX "Glove-Friendly".

## Zadania (Execution)
1. **Venue Management (M08):**
   - Stwórz `VenueRepository` do obsługi danych w tabeli `venues`.
   - Ekran `VenueSettingsScreen` (Ekran 8.1) - edycja nazwy, NIPu, adresu.
   - Obsługa logo: Upload do bucketu `branding` i wyświetlanie na TopBarze.
2. **Connectivity Logic:**
   - Dodaj `ConnectivityService` (paczka `connectivity_plus`).
   - Wyświetl dyskretny, ale wyraźny banner "BRAK INTERNETU" na górze ekranu, gdy tablet jest offline.
3. **UI/UX Audit:**
   - Przejrzyj wszystkie ekrany (M01-M07).
   - Upewnij się, że każdy przycisk "Zapisz" ma `HaccpLongPressButton`.
   - Sprawdź spójność kolorów Dark Mode (Onyx/Charcoal/Emerald).