# Sprint 1 - DB Contract

## 1. Sprint Goal
Fix root cause of broken employee onboarding by hardening HR DB contract.

## 2. Inputs (Reference Files)
- `supabase.md`
- `supabase/migrations/20260222084803_remote_schema.sql`
- `lib/features/m07_hr/repositories/hr_repository.dart`

## 3. Scope In / Out
In:
- recreate `create_employee` with venue derivation and domain validation,
- enforce unique PIN hash at DB level,
- add `update_employee_pin` RPC,
- provide smoke SQL for manual verification,
- update migration notes and rollback docs.

Out:
- visual/UI changes,
- full profile feature expansion.

## 4. Implementation Checklist (Junior)
- [ ] Review zone -> venue relation in `zones`.
- [ ] Implement migration `m07_01_create_employee_contract_fix.sql`.
- [ ] Validate all `zone_ids_input` exist and belong to one venue.
- [ ] Insert `employees.venue_id` during employee creation.
- [ ] Implement migration `m07_02_pin_hash_unique_constraint.sql`.
- [ ] Add migration `m07_03_update_employee_pin_rpc.sql`.
- [ ] Create and review `m07_04_hr_smoke_tests.sql`.
- [ ] Document rollback in `supabase/MIGRATIONS_NOTES.md`.

## 5. Tests And Definition Of Done
- [ ] Positive create: employee inserted with non-null `venue_id`.
- [ ] Negative create: duplicate PIN raises controlled DB error.
- [ ] Negative create: cross-venue zone list raises controlled DB error.
- [ ] Positive update: `update_employee_pin` updates PIN and `updated_at`.

DoD:
- migrations apply cleanly,
- smoke checks pass,
- no direct PIN writes required from client.

## 6. Risks And Rollback
Risks:
- existing duplicate `pin_hash` can block unique index migration,
- malformed historical zone assignments can fail strict validation.

Rollback:
- drop unique index,
- restore previous `create_employee` definition,
- drop `update_employee_pin` RPC.
