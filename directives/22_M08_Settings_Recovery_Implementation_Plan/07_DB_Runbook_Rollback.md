# DB Runbook + Rollback (M08 Settings)

## 1. Forward deploy (already executed)
1. `supabase db push --yes`
2. Applied migrations:
  - `20260224113000_m08_01_venues_settings_columns.sql`
  - `20260224114000_m08_02_venues_rls_update_policy.sql`
  - `20260224115000_m08_03_products_rls_scope_hardening.sql`

## 2. Post-deploy verification
1. Run app smoke:
  - manager/owner moze zapisac ustawienia i zarzadzac produktami,
  - cook/cleaner nie moze wejsc/zapisac.
2. Run SQL smoke:
  - `supabase/m08_04_settings_smoke_tests.sql`

## 3. Rollback strategy
Preferowane: **fix-forward**.
Rollback stosuj tylko przy krytycznej awarii produkcyjnej.

### 3.1 Partial rollback: tylko polityki RLS
Use when:
- aplikacja nie moze odczytac/zapisac przez bledna polityke,
- schema jest poprawna.

```sql
begin;

-- venues: rollback do poprzedniego stanu (read dla authenticated, brak update policy)
drop policy if exists "venues_select_kiosk_scope" on public.venues;
drop policy if exists "venues_update_manager_owner_kiosk_scope" on public.venues;

create policy "Enable read access for authenticated users"
  on public.venues
  as permissive
  for select
  to public
  using ((auth.role() = 'authenticated'::text));

-- products: rollback do poprzedniego stanu read-only permissive
drop policy if exists "products_select_kiosk_scope" on public.products;
drop policy if exists "products_insert_manager_owner_kiosk_scope" on public.products;
drop policy if exists "products_update_manager_owner_kiosk_scope" on public.products;
drop policy if exists "products_delete_manager_owner_kiosk_scope" on public.products;

create policy "Allow public read access"
  on public.products
  as permissive
  for select
  to public
  using (true);

create policy "Enable read access for all"
  on public.products
  as permissive
  for select
  to public
  using (true);

commit;
```

### 3.2 Full rollback: schema + RLS (M08)
Use when:
- nowe constrainty kolumn `venues` blokuja dzialanie i fix-forward nie jest mozliwy.

```sql
begin;

-- remove M08 constraints/defaults
alter table public.venues drop constraint if exists venues_temp_interval_check;
alter table public.venues drop constraint if exists venues_temp_threshold_check;
alter table public.venues drop constraint if exists venues_nip_digits_check;

alter table public.venues alter column temp_interval drop default;
alter table public.venues alter column temp_threshold drop default;

-- optional destructive step (wykonuj tylko po decyzji ownera danych)
-- alter table public.venues drop column if exists temp_interval;
-- alter table public.venues drop column if exists temp_threshold;

commit;
```

## 4. Operational fallback in app
Jesli DB rollback jest niemożliwy natychmiast:
1. Hotfix app: ukryj akcje zapisu M08 i ustaw read-only mode.
2. Tymczasowo ukryj ekran zarzadzania produktami.
3. Po stabilizacji wykonaj fix-forward polityk/RPC.

## 5. Incident checklist
1. Zidentyfikuj czy problem jest `app`, `RLS`, czy `schema constraint`.
2. Zrob snapshot bledow (Sentry/logs + SQL error text).
3. Zdecyduj `fix-forward` vs `rollback`.
4. Po przywroceniu dzialania uruchom `supabase/m08_04_settings_smoke_tests.sql` i testy M08 UI.
