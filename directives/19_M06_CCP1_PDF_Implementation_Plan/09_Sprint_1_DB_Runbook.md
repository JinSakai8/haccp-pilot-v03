# Sprint 1 DB Runbook (M06 CCP-1 report_type)

Data wykonania: 2026-02-22

## 1) Zakres zmiany

Zmiana obejmuje tylko check constraint:
- tabela: `public.generated_reports`
- constraint: `generated_reports_report_type_check`
- nowy dozwolony typ: `ccp1_temperature`

RLS i polityki nie byly modyfikowane.

## 2) Plik migracji

- `supabase/migrations/20260222130356_m06_ccp1_generated_reports_report_type.sql`

Zawartosc (apply):

```sql
alter table public.generated_reports
  drop constraint if exists generated_reports_report_type_check;

alter table public.generated_reports
  add constraint generated_reports_report_type_check
  check (
    report_type = any (
      array[
        'ccp3_cooling'::text,
        'waste_monthly'::text,
        'gmp_daily'::text,
        'ccp1_temperature'::text
      ]
    )
  ) not valid;

alter table public.generated_reports
  validate constraint generated_reports_report_type_check;
```

## 3) Apply (staging/remote)

Polecenie:

```bash
supabase db push --include-all
```

Wynik:
- migracja zastosowana na remote poprawnie.

## 4) Rollback SQL

Rollback przywraca poprzednia liste typow (bez `ccp1_temperature`):

```sql
alter table public.generated_reports
  drop constraint if exists generated_reports_report_type_check;

alter table public.generated_reports
  add constraint generated_reports_report_type_check
  check (
    report_type = any (
      array[
        'ccp3_cooling'::text,
        'waste_monthly'::text,
        'gmp_daily'::text
      ]
    )
  ) not valid;

alter table public.generated_reports
  validate constraint generated_reports_report_type_check;
```

## 5) Test evidence

### Remote (REST API)
- `ccp1_temperature` insert: PASS
- `unknown_report_type` insert: FAIL (HTTP 400, check constraint violation)
- `ccp3_cooling`: PASS
- `waste_monthly`: PASS
- `gmp_daily`: PASS

### Lokalnie (Supabase local)
- `supabase start -x vector --ignore-health-check --yes`: PASS
- Migracje odtwarzane od zera zawieraja Sprint 1: PASS
- Testy insert:
  - `ccp1_temperature`: PASS
  - `unknown_report_type`: FAIL (oczekiwane)
  - stare typy: PASS
- Test rollback + reapply:
  - rollback zastosowany: PASS
  - `ccp1_temperature` po rollback: FAIL (oczekiwane)
  - stary typ po rollback: PASS
  - ponowne apply migracji: PASS
  - `ccp1_temperature` po reapply: PASS

## 6) Operacyjna procedura rollback

1. Wykonaj rollback SQL z sekcji 4.
2. Zweryfikuj:
   - insert `ccp1_temperature` blokowany,
   - insert starych typow przechodzi.
3. W aplikacji (jesli trzeba) tymczasowo zablokuj sciezke M06 `ccp1_temperature` do czasu naprawy.
