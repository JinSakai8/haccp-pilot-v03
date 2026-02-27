# Integration Sprint 5 - Evaluation and Documentation Update

## 1. Definition of Done
1. Integracja M04<-M07 i M04<-M08 dziala E2E.
2. Migracja SQL zastosowana bez bledu i z idempotencja.
3. Testy automatyczne targetowane przechodza.
4. SQL smoke tests dla RLS i products CRUD sa zielone.
5. Brak regresji dla istniejących typow produktow.

## 2. Aktualizacja Dokumentacji Glownej
### `directives/00_Architecture_Master_Plan.md`
- Dodany cross-module dependency: M04 konsumuje referencje M07/M08.

### `supabase.md`
- Dodany `products.type='rooms'`.
- Dodany kontrakt snapshotow `selected_employee` i `selected_room`.

### `Code_description.MD`
- Dodane `employees_table` jako source dla dynamic dropdown.
- Opis mapowania snapshotow w M04 provider.

### `UI_description.md`
- Dodana zakladka `Pomieszczenia` w M08 Manage Products.
- Dodane pola wyboru pracownika/pomieszczenia w checklistach M04.

## 3. Release Checklist
1. Zastosuj migracje `20260227150000_m08_05_rooms_seed_and_type_guard.sql`.
2. Uruchom testy Flutter targetowane dla M04/M08.
3. Uruchom smoke SQL dla M08 i scenariuszy rolowych.
4. Zweryfikuj E2E cross-module na koncie manager i cook.
5. Zarchiwizuj wynik testow w artefaktach wdrozenia.

## 4. Rollback Guidance
- W razie krytycznej regresji UI: rollback release aplikacji.
- W razie potrzeby DB rollback:
  - usunac tylko seeded rekordy `type='rooms'` o nazwach startowych,
  - przywrocic poprzedni check constraint typu tylko jesli byl jawnie zarzadzany.
- Nie usuwac historycznych wpisow M04 (`haccp_logs`).
