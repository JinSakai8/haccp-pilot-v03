# Directive 12: Final Polish & M08 Implementation

## Cel
Usunięcie błędów z raportu QA (Directive 11) oraz wdrożenie ostatniego modułu M08 (Ustawienia Lokalu).

## Zadania (Execution)
1. **QA Fixes (High Priority):**
   - W `waste_registration_form_screen.dart` zamień `TextField` (KPO) na `HaccpNumPadInput`.
   - Usuń wszystkie `print()` i zastąp je `debugPrint()`.
   - Usuń hardkodowane "test_id" — upewnij się, że `venue_id` i `user_id` pochodzą z `authProvider`.
2. **M08 Venue Settings:**
   - Zaimplementuj `GlobalSettingsScreen`.
   - Dodaj edycję: Nazwa Restauracji, NIP, Adres.
   - Wdróż Upload Logo do Supabase (bucket `branding`).
3. **PDF Branding:**
   - Zaktualizuj `PdfService`, aby pobierał logo i dane lokalu z M08 i umieszczał je w nagłówku raportu.
4. **Connectivity Indicator:**
   - Dodaj w `HaccpTopBar` ikonę statusu WiFi (czerwona, gdy offline).