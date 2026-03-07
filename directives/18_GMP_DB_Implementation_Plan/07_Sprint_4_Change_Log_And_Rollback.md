# Sprint 4 Change Log And Rollback (2026-02-22)

## Zmodyfikowane pliki
- `supabase/migrations/20260222150000_sprint4_haccp_logs_data_migration.sql` (nowy)
- `directives/18_GMP_DB_Implementation_Plan/05_DB_Runbook_RLS_Migration.md` (uzupelniony o procedure Sprint 4)
- `directives/18_GMP_DB_Implementation_Plan/04_Sprint_4_5.md` (status przygotowania Sprint 4)
- `directives/18_GMP_DB_Implementation_Plan/08_Sprint_4_Execution_Report_2026-02-22.md` (raport wykonania)
- `directives/18_GMP_DB_Implementation_Plan/06_Release_Checklist.md` (status checklisty po Sprint 5)
- `directives/18_GMP_DB_Implementation_Plan/09_Sprint_5_Execution_Report_2026-02-22.md` (raport wykonania Sprint 5)

## Poprawki wykonane podczas deploy
- Fix 1: usunieto odwolanie do nieistniejacej kolumny `haccp_logs.updated_at` w backupie.
- Fix 2: zamieniono `min(uuid)` na `(array_agg(zone_id))[1]` z `count(distinct zone_id)=1`.

## Rollback danych DB (po uruchomieniu migracji)
```sql
begin;

update public.haccp_logs h
set
  form_id = b.old_form_id,
  venue_id = b.old_venue_id,
  zone_id = b.old_zone_id
from public.haccp_logs_sprint4_backup_20260222 b
where b.id = h.id;

commit;
```

## Rollback plikow (lokalnie, bez deploy)
```powershell
Remove-Item "supabase/migrations/20260222150000_sprint4_haccp_logs_data_migration.sql"
```

Jesli chcesz cofnac tez zmiany dokumentacyjne Sprint 4, przywroc:
- `directives/18_GMP_DB_Implementation_Plan/05_DB_Runbook_RLS_Migration.md`
- `directives/18_GMP_DB_Implementation_Plan/04_Sprint_4_5.md`

Najprosciej: przywroc te pliki z poprzedniej rewizji w Twoim narzedziu Git/IDE.
