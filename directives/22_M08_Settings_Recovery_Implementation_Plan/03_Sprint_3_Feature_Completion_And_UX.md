# Sprint 3: Domkniecie funkcji M08 i UX

Cel sprintu: doprowadzic M08 do pelnej zgodnosci funkcjonalnej i UX z architektura M09.
Rozmiar sprintu: sredni (1 okno kontekstowe).

## 1. Zakres
1. Routing i autoryzacja:
- dodac role guard dla `/settings` i `/settings/products`.
2. UX sukcesu i bledow:
- po zapisie stosowac `SuccessOverlay` (M09),
- wszystkie bledy mapowac na czytelne komunikaty domenowe.
3. Uporzadkowanie sekcji "System":
- jesli nie ma persystencji, oznaczyc jako "lokalne ustawienia" albo tymczasowo ukryc.
4. Produkty:
- domknac CRUD w kontekscie venue,
- usunac fallback maskujacy bledy danych produkcyjnych,
- dodac puste stany i walidacje nazw.

## 2. Kroki wykonania (dla juniora)
1. Rozszerz guard routera o M08 tak samo, jak M07.
2. Ujednolic flow zapisu ustawien:
- loading button,
- sukces overlay,
- blad z mapowaniem kodow.
3. Zdecyduj status sekcji "System":
- persystencja do DB w tym sprincie albo jawne odroczenie i ukrycie.
4. Uporzadkuj `ManageProductsScreen`:
- walidacja i deduplikacja nazwy,
- brak silent fallback danych testowych,
- czytelny empty state.
5. Dodaj podstawowe testy widgetowe M08 (settings + products).

## 3. Kryteria akceptacji
1. Direct URL `/settings` dla cook/cleaner nie daje dostepu.
2. Zapis ustawien ma spójny UX (success overlay).
3. Lista produktow nie pokazuje "awaryjnych" danych hardcoded.
4. Bledy sa zrozumiale i nie pozostawiaja UI w nieokreslonym stanie.

## 4. Testy
1. Widget: settings save success path.
2. Widget: settings error path.
3. Widget: products empty state + CRUD happy path.
4. Manual: role matrix (owner, manager, cook).

## 5. Ryzyka
1. Zmiana fallbackow moze ujawnic braki danych seedowych.
2. Guardy moga ujawnic niespojnosci w nawigacji Hub.

## 6. Wyjscie sprintu
1. Funkcjonalnie domkniety M08 dla uzytkownika koncowego.
2. Gotowosc do finalnej walidacji i release.
