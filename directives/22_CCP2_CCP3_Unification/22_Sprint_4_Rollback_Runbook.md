# Sprint 4 Rollback Runbook (CCP3 generated_reports backfill)

Data: 2026-02-26  
Zakres: migracja `20260226200000_sprint4_ccp3_generated_reports_venue_backfill.sql`

## Cel
Bezpiecznie cofn¹æ zmiany backfill `venue_id`/`metadata` dla `generated_reports.report_type='ccp3_cooling'`.

## Za³o¿enia
1. Backup zosta³ utworzony przez migracjê:
- `public.generated_reports_ccp3_backfill_20260226_backup`.
2. Rollback dotyczy tylko rekordów z backupu.
3. Nie usuwamy danych raportów ani plików w storage.

## Kroki rollback
1. Zatrzymaj operacje release (freeze write path dla M06, jeœli mo¿liwe).
2. Wykonaj rollback SQL w transakcji:

```sql
begin;

update public.generated_reports g
set
  venue_id = b.previous_venue_id,
  metadata = b.previous_metadata,
  storage_path = b.previous_storage_path
from public.generated_reports_ccp3_backfill_20260226_backup b
where g.id = b.report_id
  and g.report_type = 'ccp3_cooling';

commit;
```

3. Zweryfikuj wynik rollback (queries kontrolne):

```sql
select count(*) as restored_rows
from public.generated_reports g
join public.generated_reports_ccp3_backfill_20260226_backup b
  on b.report_id = g.id
where g.report_type = 'ccp3_cooling';

select
  count(*) as still_marked_backfill
from public.generated_reports
where report_type = 'ccp3_cooling'
  and (
    metadata ? 'ccp3_backfill_status'
    or metadata ? 'ccp3_backfill_reason'
  );
```

4. Je¿eli rollback poprawny, zdecyduj:
- albo zostawiæ tabelê backup dla audytu,
- albo przenieœæ do archiwum zgodnie z polityk¹ DBA.

## Procedura awaryjna (gdy transakcja rollback nie przechodzi)
1. Przerwij transakcjê (`rollback;`).
2. Zbierz konfliktuj¹ce rekordy i klucze unikalnoœci:

```sql
select
  venue_id,
  report_type,
  generation_date,
  count(*) as duplicates
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
group by venue_id, report_type, generation_date
having count(*) > 1;
```

3. Oznacz release jako `NO-GO` do czasu rêcznego usuniêcia konfliktów.
4. Po korekcie konfliktów wykonaj rollback ponownie.

## Post-rollback checklist
1. Archiwum M06 dla CCP3 dzia³a jak przed migracj¹.
2. Brak nowych b³êdów RLS.
3. Wyniki query walidacyjnych s¹ zapisane w raporcie release.
