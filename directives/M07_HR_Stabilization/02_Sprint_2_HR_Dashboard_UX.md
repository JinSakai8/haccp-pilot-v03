# Sprint 2 - HR Dashboard UX Refactor

## 1. Sprint Goal
Replace oversized alert cards with compact, readable HR dashboard sections.

## 2. Inputs (Reference Files)
- `UI_description.md`
- `lib/features/m07_hr/screens/hr_dashboard_screen.dart`
- `lib/core/constants/design_tokens.dart`

## 3. Scope In / Out
In:
- compact status summary,
- short alert lists with clear CTA,
- loading/empty/error states,
- preserve glove-friendly dark design.

Out:
- full profile redesign,
- new backend endpoints.

## 4. Implementation Checklist (Junior)
- [ ] Replace old large cards with 3 compact status cards.
- [ ] Add two compact alert sections: expired and expiring soon.
- [ ] Limit visible rows per section and add `Zobacz wszystkie` CTA.
- [ ] Keep direct navigation from list row to `/hr/employee/:id`.
- [ ] Keep quick action buttons to list/add employee.
- [ ] Validate readability on 1366x768 viewport.

## 5. Tests And Definition Of Done
- [ ] Top bar + status summary + alert sections visible without heavy blocking layout.
- [ ] No oversized cards consuming most of viewport height.
- [ ] Tap on employee row opens profile screen.
- [ ] Empty states shown when no alerts.

DoD:
- dashboard stays readable with and without data,
- visual hierarchy matches stabilization target.

## 6. Risks And Rollback
Risks:
- over-compression can hurt readability on smaller screens,
- list density can break touch ergonomics.

Rollback:
- restore previous dashboard file from git history if UX regression is severe.
