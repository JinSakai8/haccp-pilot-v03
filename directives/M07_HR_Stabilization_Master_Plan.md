# M07 HR Stabilization Master Plan

## 1. Business Goal And Scope
Scope: `Krytyczne + Stabilizacja`.

Primary outcomes:
- fix employee creation so new records are fully usable in kiosk flow,
- reduce visual overload on HR dashboard,
- make Flutter <-> Supabase HR contract explicit and stable,
- deliver sprint-ready handoff docs for next conversation.

Out of scope:
- full M07 extension (document scans, full activity analytics, deep profile redesign).

## 2. Current Audit
Working:
- `/hr*` role guard exists,
- employee list and basic filters work,
- sanepid date and active toggle use RPC,
- PIN uniqueness pre-check exists in UI.

Broken / high risk:
- `create_employee` previously did not guarantee `employees.venue_id`,
- no hard DB uniqueness on `pin_hash`,
- HR dashboard cards were oversized and blocked screen overview,
- `updatePin` used direct table update instead of RPC,
- no focused M07 regression tests.

## 3. Target Contract (Flutter <-> Supabase)
Supabase contract:
- `create_employee(...)` derives `venue_id` from `zone_ids_input`, validates single-venue domain, raises domain errors,
- `employees.pin_hash` has unique index,
- `update_employee_pin(...)` RPC is the only write path for PIN changes.

Flutter contract:
- `HrRepository` maps domain RPC errors to operator-friendly messages,
- `updatePin` calls `update_employee_pin` RPC,
- Add Employee flow blocks duplicate submit and filters zones to current venue context,
- HR dashboard uses compact summary + short alert lists.

## 4. Sprint Plan
1. Sprint 1: DB Contract Fix
2. Sprint 2: HR Dashboard UX Refactor
3. Sprint 3: Add Employee Flow Stabilization
4. Sprint 4: QA, Regression, Release Pack

Detailed steps are in sprint files in `directives/M07_HR_Stabilization/`.

## 5. DB Migration Plan And Rollback
Applied migration artifacts:
- `supabase/migrations/20260224100000_m07_01_create_employee_contract_fix.sql`
- `supabase/migrations/20260224101000_m07_02_pin_hash_unique_constraint.sql`
- `supabase/migrations/20260224102000_m07_03_update_employee_pin_rpc.sql`
- `supabase/m07_04_hr_smoke_tests.sql` (manual verification)

Rollback references:
- each migration has rollback steps in `supabase/MIGRATIONS_NOTES.md`.

## 6. Final Acceptance Criteria
- new employee has non-null `venue_id` and can complete login + kiosk context,
- duplicate PIN is blocked at DB level and surfaced clearly in UI,
- HR dashboard shows compact alert sections without oversized cards,
- PIN updates happen only through RPC,
- M07 alert classification test suite exists and passes in CI/runtime environment.

## 7. Attachments For New Conversation
- Always attach: this master file + selected sprint file.
- Sprint 1 add: `supabase.md`.
- Sprint 2 add: `UI_description.md`.
- Sprint 3 add: `Code_description.MD`.
- Sprint 4 add: no extra by default; if auth regression appears also add `directives/00_Architecture_Master_Plan.md`.
