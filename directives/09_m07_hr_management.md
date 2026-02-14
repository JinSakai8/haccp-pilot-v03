# Directive 09: Module M07 - HR & Employee Management

## Cel
Budowa panelu administracyjnego do zarządzania personelem, uprawnieniami (PIN) i monitoringiem badań Sanepidu.

## Zadania (Execution)
1. **Repository:** Stwórz `HrRepository` obsługujący CRUD na tabeli `employees`.
2. **UI Screens:** - Zaimplementuj `EmployeeListScreen` (Ekran 7.4) z oznaczeniem statusu badań (Zielony/Żółty/Czerwony).
   - Zaimplementuj `AddEmployeeScreen` (Ekran 7.3) z customowym widgetem do nadawania 4-cyfrowego PIN-u.
3. **Logic:** Dodaj w `profiles` (Supabase) pole `sanepid_checkup_expiry` i zintegruj je z widokiem.
4. **Guardianship:** Upewnij się, że te ekrany są dostępne TYLKO dla użytkowników z rolą `manager` lub `owner`.

## Rygor
- Zgodność z Master Planem: Feature-First structure w `lib/features/m07_hr/`.
- UX: Duże przyciski "Dodaj" i "Zablokuj" (Glove-Friendly).
