# DB Runbook: RLS + Migration (`haccp_logs`)

## Zakres
Dokument operacyjny do wykonania zmian SQL w bezpiecznej kolejności.

## Kolejność techniczna
1. Backup metadanych i snapshot rekordów.
2. Deploy migracji struktur (indeksy/constraints).
3. Deploy polityk RLS.
4. Walidacja odczytów/zapisów aplikacji.
5. Migracja danych historycznych.
6. Testy regresji i wydajności.

## Sprint 4: Procedura wykonania (data migration)

### Artefakt migracji
- `supabase/migrations/20260222150000_sprint4_haccp_logs_data_migration.sql`

### Precheck (przed `db push`)
```sql
select form_id, count(*) as cnt
from public.haccp_logs
where category = 'gmp'
group by form_id
order by form_id;

select count(*) as missing_venue_id
from public.haccp_logs
where venue_id is null;

select count(*) as missing_zone_id
from public.haccp_logs
where zone_id is null;
```

### Deploy
- `supabase db push`

### Walidacja po deploy
```sql
-- 1) Legacy form_id powinny zniknac
select count(*) as legacy_form_ids
from public.haccp_logs
where category = 'gmp'
  and form_id in ('meat_roasting_daily', 'delivery_control_daily');

-- 2) Raport po migracji
select form_id, count(*) as cnt
from public.haccp_logs
where category = 'gmp'
group by form_id
order by form_id;

select count(*) as missing_venue_id
from public.haccp_logs
where venue_id is null;

select count(*) as missing_zone_id
from public.haccp_logs
where zone_id is null;
```

### Rollback danych (Sprint 4)
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

## Komendy (szkic)
- `supabase db pull`
- `supabase migration new <name>`
- `supabase db push`

## Konkret Sprint 3
- Migracja: `supabase/migrations/20260222123000_sprint3_haccp_logs_hardening.sql`
- Aplikacja musi wywołać RPC `set_kiosk_context(employee_id_input, zone_id_input)` po wyborze strefy.
- Przy wylogowaniu/zmianie użytkownika aplikacja powinna wywołać `clear_kiosk_context()`.

## Smoke test SQL po `db push`
```sql
-- 1) Kontekst kiosku ustawiony:
select * from public.kiosk_sessions where auth_user_id = auth.uid();

-- 2) Odczyt w scope:
select count(*)
from public.haccp_logs
where category = 'gmp'
  and form_id = 'food_cooling';

-- 3) Negatywny INSERT (inny venue/user) powinien zostać zablokowany przez RLS:
insert into public.haccp_logs (venue_id, user_id, category, form_id, data, zone_id)
values (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000000',
  'gmp',
  'food_cooling',
  '{}'::jsonb,
  null
);
```

## Kontrole po wdrożeniu
- [ ] SELECT/INSERT dla aktywnego lokalu działa.
- [ ] Odczyt cross-venue zablokowany.
- [ ] Zapytania CCP-3 mają prawidłowy plan wykonania.

## Rollback
- [ ] Przywrócić poprzednie polityki RLS.
- [ ] Cofnąć migrację danych `form_id` wg mapy odwrotnej.
- [ ] Zweryfikować integralność rekordów po rollback.

## Uwagi
- W modelu kiosk najpierw testować polityki na środowisku staging.
- Nie łączyć hardeningu RLS i dużej migracji danych w jednym deployu.
