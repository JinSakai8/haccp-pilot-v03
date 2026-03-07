# Sprint 4 - QA Regression Release

## 1. Sprint Goal
Protect M07 fixes with targeted tests, regression checklist, and release runbook.

## 2. Inputs (Reference Files)
- `directives/M07_HR_Stabilization_Master_Plan.md`
- `test/features/m07_hr/hr_alerts_snapshot_test.dart`
- `supabase/MIGRATIONS_NOTES.md`

## 3. Scope In / Out
In:
- M07 test coverage for alert logic and critical flows,
- regression checks for M01 auth + zone selection + kiosk context,
- release checklist and rollback notes,
- short implementation status report.

Out:
- broad refactor outside M07 stabilization,
- unrelated module enhancements.

## 4. Implementation Checklist (Junior)
- [ ] Run M07 targeted tests.
- [ ] Run smoke auth flow: login -> zone select -> hub.
- [ ] Run smoke M07 flow: add employee -> list -> profile -> pin update.
- [ ] Validate DB smoke script results from Sprint 1.
- [ ] Prepare release note with known limitations.

## 5. Tests And Definition Of Done
- [ ] M07 tests pass in execution environment.
- [ ] No regression in login and kiosk context setup.
- [ ] No regression in HR list/profile navigation.

DoD:
- release checklist completed,
- rollback path documented and verified.

## 6. Risks And Rollback
Risks:
- missing flutter CLI in environment can delay full test suite,
- hidden dependency regressions can appear outside M07.

Rollback:
- revert M07 UI/repository commits,
- rollback DB migrations using documented SQL steps.
