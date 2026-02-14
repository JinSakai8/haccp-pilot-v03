# Directive 07: Module M05 - BDO & Custom Glove-Friendly Camera

## Cel

Implementacja modułu odpadów z natywną obsługą aparatu i uploadem do Supabase Storage.

## Zadania (Execution)

1. **Dependencies:** Dodaj `camera`, `path_provider` oraz `flutter_image_compress` do `pubspec.yaml`.
2. **Custom Camera UI:** - Stwórz `HaccpCameraScreen`.
   - Elementy: Pełny podgląd, wielki przycisk migawki (80x80dp), brak małych ikon systemowych.
   - Po zrobieniu zdjęcia: Ekran "Review" z dwoma wielkimi przyciskami: "Ponów" (Orange) i "Zatwierdź" (Green).
3. **Image Logic:** - Implementacja kompresji (max 1024px, quality 80%) przed wysyłką.
   - Serwis `StorageService` do obsługi uploadu do bucketu `waste-docs`.
4. **Form Integration:**
   - Ekran rejestracji odpadu wykorzystujący `HaccpStepper` do wagi i grid kafelków do wyboru typu odpadu.

## Rygor Techniczny

- Wszystkie interakcje foto muszą być "One-Hand / Glove Friendly".
- Zdjęcie musi zostać wysłane przed ostatecznym zapisem rekordu w bazie (aby mieć pewność, że URL jest poprawny).
