# Directive 03: Authentication Flow (Module M01)

## Cel

Zaimplementowanie pełnej logiki logowania pracownika za pomocą kodu PIN, zgodnie z ekranami 1.1, 1.2 i 1.3 ze Stitcha oraz bazą danych Supabase.

## Zadania do wykonania (Execution)

1. **Model Danych:** Utwórz model `Employee` w `lib/core/models/` odpowiadający tabeli `employees` (id, name, pin_hash, role, is_active).
2. **Auth Service:** W `lib/core/services/auth_service.dart` stwórz serwis Riverpod, który:
   - Przyjmuje PIN z klawiatury.
   - Haszuje go (SHA-256) i porównuje z bazą Supabase.
   - Pobiera przypisane strefy (`zones`) dla danego pracownika z tabeli `employee_zones`.
3. **Logika Ekranów (UI Integration):**
   - **Ekran 1.1 (Splash):** Sprawdź, czy sesja jest aktywna. Jeśli nie -> przekieruj do 1.2.
   - **Ekran 1.2 (PIN Pad):** Podepnij przyciski numeryczne wygenerowane w Stitch pod funkcję logowania. Dodaj prosty "Loading Indicator" podczas sprawdzania PIN-u.
   - **Ekran 1.3 (Zone Selection):** Jeśli pracownik ma przypisaną więcej niż jedną strefę, wyświetl listę (z bazy!). Po wyborze – zapisz `active_zone_id` w stanie aplikacji (Riverpod) i przejdź do Dashboardu.
4. **Zabezpieczenie (Glove-Friendly):** Upewnij się, że po błędnym wpisaniu PIN-u pojawia się duży, czerwony komunikat "BŁĘDNY PIN", który znika po 3 sekundach.

## Oczekiwany rezultat

Użytkownik może wpisać PIN na tablecie. System sprawdza go w Supabase. Jeśli PIN jest poprawny, użytkownik wybiera strefę i ląduje na głównym Dashboardzie (Hub).
