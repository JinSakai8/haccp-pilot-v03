# Release Checklist (M08 Settings Recovery)

## A. Pre-release
- [x] Sprint 1-4 dostarczone.
- [x] Migracje M08 wypchniete na remote (`supabase db push`).
- [x] Testy widgetowe M08 przechodza.
- [x] Testy M08 po zmianach S3/S4 przechodza (`8 passed, 0 failed`).
- [x] DB/Storage E2E przez CLI wykonany na staging (`supabase/.temp/m08_cli_e2e_results.json`).
- [ ] Opcjonalny audit SQL: `supabase/m08_04_settings_smoke_tests.sql`.

## B. Security / Access
- [x] Guard routera blokuje `/settings` i `/settings/products` dla `cook/cleaner`.
- [x] RLS `venues` scoped do `kiosk_sessions` + update tylko `manager/owner`.
- [x] RLS `products` scoped do `kiosk_sessions` + write tylko `manager/owner`.
- [x] Potwierdzone scenariusze allow/deny manager vs cook (CLI DB E2E).

## C. UX / Functional
- [x] Zapis ustawien pokazuje `HaccpSuccessOverlay`.
- [x] Bledy zapisu mapowane na komunikaty domenowe.
- [x] Brak fallbackowych danych produktow maskujacych bledy.
- [x] Empty state produktow pokazuje czytelny komunikat.
- [x] Sekcja `System` opisana jako lokalna (bez zapisu w DB).
- [x] Brak silent fail uploadu logo (retry/cancel + deny case).

## D. Evidence (2026-02-24)
- `flutter test test/features/m08_settings --reporter compact` -> PASS
- `flutter test --reporter compact` -> PASS (`43 passed, 1 skipped, 0 failed`)
- `flutter analyze` (scope M08/router/repo/testy M08) -> PASS

## D2. Evidence (2026-02-27)
- `C:\scr\flutter\bin\flutter.bat test test/features/m08_settings` -> PASS (`8 passed, 0 failed`)
- Dodany test payloadu M08 (`nip='' -> NULL`, walidacja `name/address/nip`) -> PASS
- `supabase db push` -> zastosowano `20260227110000_m08_04_branding_storage_hardening.sql`
- CLI DB E2E -> PASS (`supabase/.temp/m08_cli_e2e_results.json`)

## E. Rollout
- [ ] Canary: 1 lokal (manager + cook) przez 24h.
- [ ] Monitoring bledow M08 przez 48h.
- [ ] Decyzja full rollout po canary.

## F. Sign-off
- [ ] Tech Lead
- [ ] Product Owner
- [ ] Ops/DB Owner
