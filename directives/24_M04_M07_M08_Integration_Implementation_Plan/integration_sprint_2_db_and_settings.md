# Integration Sprint 2 - DB and M08 Settings

## 1. Cel Sprintu
Dostarczanie slownika pomieszczen przez M08 z wykorzystaniem istniejacego modelu `products`.

## 2. Zakres DB
### 2.1 Migracja
Plik: `supabase/migrations/20260227150000_m08_05_rooms_seed_and_type_guard.sql`

Zakres:
- Seed globalny `products.type='rooms'`:
  - `kuchnia`
  - `myjnia`
  - `pomieszczenie do obierania warzyw`
  - `bar`
- Idempotencja: `on conflict (name, venue_id) do nothing`.
- Guard legacy: jesli istnieje `products_type_check`, rozszerzenie o `rooms`.

### 2.2 RLS
- Brak zmian policy.
- Reuse `products_select_kiosk_scope` i `products_*_manager_owner_kiosk_scope`.

## 3. Zakres M08 (UI/Repo)
### 3.1 UI
Plik: `lib/features/m08_settings/screens/manage_products_screen.dart`

Zmiany:
- Dodana 4 zakladka: `Pomieszczenia` (`type='rooms'`).
- CRUD dialog wspiera nowy typ w tej samej sciezce co inne kategorie.

### 3.2 Repo/Provider
Plik: `lib/features/shared/repositories/products_repository.dart`

Zmiany:
- Brak nowych metod.
- Potwierdzony reuse `getProducts('rooms')`.

## 4. Kryteria Akceptacji Sprintu
1. Manager moze dodac/edytowac/usunac rekord `rooms`.
2. Cook nie moze modyfikowac `rooms`.
3. Zakladki `cooling/roasting/general` bez regresji.
4. Empty state dziala dla 4 kategorii.

## 5. Testy Sprintu
- `test/features/m08_settings/m08_sprint3_test.dart`:
  - override `productsProvider('rooms')`
  - widocznosc tabu `Pomieszczenia`
- SQL smoke:
  - insert/update/delete `products.type='rooms'` jako manager,
  - denial write jako cook.
