# Integration Sprint 3 - M04 GHP Forms

## 1. Cel Sprintu
Podpiecie formularzy M04 do dynamicznych danych M07 i M08 z kontraktem snapshotowym.

## 2. Personel (M04 <- M07)
### Pliki
- `lib/features/shared/config/checklist_definitions.dart`
- `lib/features/shared/widgets/dynamic_form/haccp_dropdown.dart`

### Zmiany
- Dodane required pole `selected_employee` w kategorii `personnel`.
- Konfiguracja pola: `source='employees_table'`.
- Dropdown pobiera pracownikow z `hrEmployeesProvider`.
- Filtrowanie opcji: tylko `isActive=true`, scope po aktualnej strefie.

## 3. Pomieszczenia (M04 <- M08)
### Pliki
- `lib/features/shared/config/checklist_definitions.dart`
- `lib/features/shared/widgets/dynamic_form/haccp_dropdown.dart`

### Zmiany
- Dodane required pole `selected_room` w kategorii `rooms`.
- Konfiguracja pola: `source='products_table'`, `type='rooms'`.
- Dropdown pobiera `productsProvider('rooms')`.

## 4. Dynamic Form Engine
### Pliki
- `lib/features/shared/widgets/dynamic_form/haccp_dropdown.dart`

### Zmiany
- Ujednolicony model opcji dropdown: `id + label`.
- `state.value` przechowuje `id` wybranej opcji.
- UI renderuje etykiete (`label`) na podstawie `id`.

## 5. Submission Mapping (Snapshot)
### Plik
- `lib/features/m04_ghp/providers/ghp_provider.dart`

### Zmiany
- Przed zapisem M04 payload jest wzbogacany o snapshoty:
  - `selected_employee: {id,name}`
  - `selected_room: {id,name}`
- Zachowany kontrakt:
  - `execution_date`
  - `execution_time`
  - `answers`
  - `notes` (opcjonalne)

## 6. Historia M04
### Plik
- `lib/features/m04_ghp/screens/ghp_history_screen.dart`

### Zmiany
- Render map snapshotowych po `name` (fallback: `id`).
- Historia jest czytelna po dezaktywacji/usunieciu encji referencyjnej.

## 7. Testy Sprintu
- `test/features/m04_ghp/ghp_checklist_validation_test.dart`
  - obecność pola `Pracownik` i `Pomieszczenie`.
- `test/features/m04_ghp/ghp_submission_contract_test.dart`
  - mapowanie snapshotow `{id,name}`.
