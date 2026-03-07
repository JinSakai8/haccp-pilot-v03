# Sprint 4-5 (Data Migration + Release)

## Sprint 4: Migracja danych historycznych (0.5-1 dzień)

### Cel
Zsynchronizować stare rekordy z nowym kontraktem.

### Status przygotowania (2026-02-22)
- [x] Przygotowana migracja SQL: `supabase/migrations/20260222150000_sprint4_haccp_logs_data_migration.sql`.
- [x] Przygotowany scenariusz walidacji i rollback: `directives/18_GMP_DB_Implementation_Plan/05_DB_Runbook_RLS_Migration.md`.
- [x] Wykonanie `supabase db push` na środowisku docelowym.
- [x] Raport przed/po z realnych danych po wdrożeniu.

### Zadania
- [x] S4.1 Migracja `form_id`:
  - `meat_roasting_daily` -> `meat_roasting`,
  - `delivery_control_daily` -> `delivery_control`.
- [x] S4.2 Uzupełnić brakujące `zone_id`/`venue_id` tam, gdzie to bezpieczne.
- [x] S4.3 Wygenerować raport przed/po.
- [x] S4.4 Przygotować rollback danych.

### Wynik wykonania Sprint 4 (2026-02-22)
- Precheck: `haccp_logs` = 9 rekordow, `food_cooling=9`, legacy `form_id` = 0.
- Braki kluczy: `venue_id IS NULL` = 0, `zone_id IS NULL` = 0.
- Migracja wdrozona: `supabase db push` (po 2 poprawkach kompatybilnosci SQL).
- Backup rollback: tabela `haccp_logs_sprint4_backup_20260222` utworzona, 0 rekordow.

### Kryteria akceptacji
- [x] 100% migrowalnych rekordów ma docelowy `form_id`.
- [ ] Historia GMP i CCP-3 są spójne po migracji.

---

## Sprint 5: Testy końcowe, release i stabilizacja (1-1.5 dnia)

### Cel
Wdrożyć zmiany bez regresji i potwierdzić stabilność operacyjną.

### Zadania
- [ ] S5.1 E2E:
  - zapis chłodzenia -> CCP-3,
  - zapis pieczenia/dostaw -> historia,
  - separacja stref/lokali.
- [x] S5.2 Naprawić testy niespójne z aktualnym modelem (`test/db_consistency_test.dart`).
- [x] S5.3 Przejść checklistę release.
- [ ] S5.4 Canary rollout (lokal testowy / ograniczona grupa).
- [ ] S5.5 48h obserwacji + decyzja go-live close.

### Wynik wykonania Sprint 5 (2026-02-22)
- Testy uruchomione przez `C:\scr\flutter\bin\flutter.bat`.
- Wynik: `flutter test` przechodzi w calosci.
- Podsumowanie testow: **19 passed, 1 skipped, 0 failed**.
- Status S5.1: automatyczne testy repo/UI przechodza; pelne E2E operacyjne pozostaje do manualnego potwierdzenia na canary.
- Status S5.4/S5.5: oczekuje na wdrozenie canary i 48h obserwacji.

### Kryteria akceptacji
- [ ] Brak błędów krytycznych po 48h.
- [ ] Potwierdzenie biznesowe poprawy GMP/CCP-3.

### Wyjście sprintu
- Stabilna wersja produkcyjna.
