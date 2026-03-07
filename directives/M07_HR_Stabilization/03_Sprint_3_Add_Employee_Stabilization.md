# Sprint 3 - Add Employee Stabilization

## 1. Sprint Goal
Stabilize add employee flow after DB contract hardening.

## 2. Inputs (Reference Files)
- `Code_description.MD`
- `lib/features/m07_hr/screens/add_employee_screen.dart`
- `lib/features/m07_hr/repositories/hr_repository.dart`
- `lib/features/m07_hr/providers/hr_provider.dart`

## 3. Scope In / Out
In:
- map RPC/domain errors to clear operator messages,
- prevent duplicate submit,
- filter selectable zones to current venue context,
- switch PIN update to RPC path only.

Out:
- complete M07 feature expansion,
- non-critical cosmetic polish.

## 4. Implementation Checklist (Junior)
- [ ] Add repository-level error mapping for M07 domain errors.
- [ ] Use mapped messages in Add Employee UI snackbar path.
- [ ] Add loading state and submit lock on create action.
- [ ] Filter zone chips by current venue context.
- [ ] Remove direct table update for PIN and use RPC `update_employee_pin`.

## 5. Tests And Definition Of Done
- [ ] Successful create returns to previous screen with success signal.
- [ ] Duplicate PIN shows deterministic readable error.
- [ ] Invalid zone combination shows deterministic readable error.
- [ ] PIN update works through RPC only.

DoD:
- no direct `employees.pin_hash` update in client code,
- add flow is deterministic and resilient to race/error cases.

## 6. Risks And Rollback
Risks:
- incomplete error mapping can surface generic backend messages,
- venue context missing in edge login states can over-filter zones.

Rollback:
- temporary fallback to generic error display,
- restore previous add screen and repository methods if release is blocked.
