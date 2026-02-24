# Release Checklist (M08 Settings Recovery)

## A. Pre-release
- [x] Sprint 1-3 dostarczone.
- [x] Migracje M08 wypchniete na remote (`supabase db push`).
- [x] Testy widgetowe M08 przechodza.
- [x] Pelny `flutter test` przechodzi.
- [ ] Smoke SQL M08 wykonany na staging (`supabase/m08_04_settings_smoke_tests.sql`).

## B. Security / Access
- [x] Guard routera blokuje `/settings` i `/settings/products` dla `cook/cleaner`.
- [x] RLS `venues` scoped do `kiosk_sessions` + update tylko `manager/owner`.
- [x] RLS `products` scoped do `kiosk_sessions` + write tylko `manager/owner`.
- [ ] Potwierdzone manualnie scenariusze allow/deny na staging dla wszystkich rol.

## C. UX / Functional
- [x] Zapis ustawien pokazuje `HaccpSuccessOverlay`.
- [x] Bledy zapisu mapowane na komunikaty domenowe.
- [x] Brak fallbackowych danych produktow maskujacych bledy.
- [x] Empty state produktow pokazuje czytelny komunikat.
- [x] Sekcja `System` opisana jako lokalna (bez zapisu w DB).

## D. Evidence (2026-02-24)
- `flutter test test/features/m08_settings --reporter compact` -> PASS
- `flutter test --reporter compact` -> PASS (`43 passed, 1 skipped, 0 failed`)
- `flutter analyze` (scope M08/router/repo/testy M08) -> PASS

## E. Rollout
- [ ] Canary: 1 lokal (manager + cook) przez 24h.
- [ ] Monitoring bledow M08 przez 48h.
- [ ] Decyzja full rollout.

## F. Sign-off
- [ ] Tech Lead
- [ ] Product Owner
- [ ] Ops/DB Owner
