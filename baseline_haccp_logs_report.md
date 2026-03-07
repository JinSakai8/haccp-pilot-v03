# Baseline HACCP Logs Report (Sprint 0)

Date: **2026-02-22**  
Branch: `hotfix/gmp-db-audit`

## 1) Diagnostic snapshot (`haccp_logs`)

Source query method: Supabase REST API (`/rest/v1/haccp_logs?select=form_id,zone_id,venue_id`), executed on 2026-02-22.

- Total records: **9**
- Records per `form_id`:
  - `food_cooling`: **9**
- Records with `zone_id IS NULL`: **0**
- Records with `venue_id IS NULL`: **0**

## 2) Sprint 0 schema baseline status

- `supabase db pull`: wykonane pomyslnie dnia **2026-02-22** po naprawie historii migracji.
- Wygenerowany pelny snapshot schema:
  - `supabase/migrations/20260222084803_remote_schema.sql`
  - skopiowany do artefaktu: `baseline_schema.sql`
- Historia migracji po pull:
  - `20260222084436` (naprawa historii przez `migration repair`)
  - `20260222084803` (wlasciwy zrzut remote schema)

## 3) Remote vs repo quick comparison

- Remote schema contains both canonical and legacy log tables:
  - `public.haccp_logs` (active),
  - `public.gmp_logs`, `public.ghp_logs` (legacy, currently empty).
- App runtime repositories for GMP/GHP are aligned to `haccp_logs`.
- There are still legacy references in historical docs/older SQL files; no runtime blocker for Sprint 1, but cleanup remains advisable in later sprints.

## 4) Frozen target `form_id` contract (S0.4)

Approved canonical values:

- `food_cooling`
- `meat_roasting`
- `delivery_control`

Implemented in code and tests:

- constants + mapping: `lib/features/m03_gmp/config/gmp_form_ids.dart`
- contract tests: `test/features/m03_gmp/gmp_form_id_contract_test.dart`
