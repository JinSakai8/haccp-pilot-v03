# Sprint 4 Change Log (2026-02-24)

## Zmodyfikowane obszary
- M08 router guard (`/settings`, `/settings/products`) -> manager/owner only.
- M08 settings UX:
  - success overlay,
  - error mapping,
  - local-only oznaczenie sekcji System.
- M08 products:
  - usuniecie fallbackow danych,
  - deduplikacja + walidacja nazwy,
  - empty state.
- DB hardening (Sprint 2 migrations) wdrozone na remote.

## QA Evidence
- `flutter test test/features/m08_settings --reporter compact` -> PASS
- `flutter test --reporter compact` -> PASS
- `flutter analyze` (scope M08) -> PASS

## Otwarte punkty przed full release
- Manual execution SQL smoke na staging (`supabase/m08_04_settings_smoke_tests.sql`).
- Canary + 48h obserwacji operacyjnej.
