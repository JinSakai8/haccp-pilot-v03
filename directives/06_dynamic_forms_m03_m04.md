# Directive 06: Dynamic Forms Engine (M03/M04)

## Cel
Budowa silnika "Meta-Driven UI", który renderuje formularze na podstawie JSONB z Supabase.

## Kluczowe Zasady (Constraints)
1. **No-Keyboard Policy:** Pola numeryczne mają używać wyłącznie `HaccpNumPad` lub `HaccpStepper`. Żadnej klawiatury systemowej!
2. **Glove-Friendly:** Wszystkie elementy (Toggle, Przyciski) muszą mieć min. 60x60dp.
3. **Typy Pól:** Silnik musi obsługiwać: `toggle` (Tak/Nie), `stepper` (+/-), `photo` (Camera Integration), `numpad` (Wpisanie temp).
4. **Wersjonowanie:** Przy zapisie do `gmp_logs`/`ghp_logs` zapisz aktualną wersję szablonu.

## Zadania (Execution)
1. Utwórz `lib/features/shared/widgets/dynamic_form_renderer.dart`.
2. Zaimplementuj logikę `ValidationEngine`: 
   - Jeśli pole `required` jest puste -> blokuj zapis.
   - Jeśli wartość poza zakresem `soft_min/max` -> pokaż żółty warning i wymagaj komentarza.
3. Podepnij ekrany M03 i M04 pod ten silnik.