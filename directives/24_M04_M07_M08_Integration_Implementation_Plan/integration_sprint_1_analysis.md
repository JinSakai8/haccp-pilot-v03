# Integration Sprint 1 - Analysis

## 1. Cel Sprintu
Potwierdzenie aktualnych punktow integracji oraz zamkniecie listy zmian przed implementacja.

## 2. Inwentaryzacja Plikow
### M08
- `lib/features/m08_settings/screens/manage_products_screen.dart`
- `lib/features/shared/repositories/products_repository.dart`
- `lib/features/m08_settings/providers/m08_providers.dart`

### M04
- `lib/features/m04_ghp/screens/ghp_checklist_screen.dart`
- `lib/features/m04_ghp/providers/ghp_provider.dart`
- `lib/features/shared/config/checklist_definitions.dart`
- `lib/features/shared/widgets/dynamic_form/dynamic_form_renderer.dart`
- `lib/features/shared/widgets/dynamic_form/haccp_dropdown.dart`

### M07
- `lib/features/m07_hr/repositories/hr_repository.dart`
- `lib/features/m07_hr/providers/hr_provider.dart`
- `lib/core/models/employee.dart`

### Testy
- `test/features/m08_settings/*`
- `test/features/m04_ghp/*`

## 3. Weryfikacja Wzorca Referencyjnego
Wzorzec `cooling`/`roasting` w M08:
- Tab-based UI,
- CRUD przez `ProductsRepository`,
- scope danych przez `venue_id` + RLS.

Wniosek: `rooms` wdrazamy analogicznie do istniejących kategorii bez nowej warstwy.

## 4. SQL Reconnaissance
- Aktywne policy: `products_*_kiosk_scope` (read scoped + write manager/owner).
- Brak wymaganego check-constraint typu w aktualnym baseline.
- Potencjalne srodowiska legacy moga miec `products_type_check`; migracja zawiera guard.

## 5. Gap List
1. Brak `rooms` w M08 tabs/dialog type map.
2. Brak `employees_table` jako `source` dla dropdown renderer.
3. Brak pol `selected_employee` i `selected_room` w definicjach GHP.
4. Brak snapshot mapowania `id+name` podczas submit M04.
5. Historia M04 nie formatuje map snapshotow do czytelnej nazwy.

## 6. Exit Criteria
- Zamknieta checklista zmian dla: DB, repository/provider, UI, testy, docs.
- Jednoznaczny kontrakt danych dla `haccp_logs.data.answers`.
- Potwierdzona kompatybilnosc wsteczna dla `cooling/roasting/general`.
