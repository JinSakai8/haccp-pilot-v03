# Efento Timezone Fix Design

## Context
- `temperature_logs.recorded_at` is stored as `TIMESTAMPTZ`.
- New Efento measurements arrive with wall-clock timestamps that represent local `Europe/Warsaw` time.
- The current proxy converts `YYYY-MM-DD HH:mm:ss` values with `Date.UTC(...)`, which treats local Warsaw time as UTC and shifts new rows by `-1h` on 2026-03-07.
- The Flutter M02 UI formats `recorded_at` directly without `toLocal()`, so UTC values are shown instead of local kiosk time.

## Chosen approach
- Keep database storage in UTC with `TIMESTAMPTZ`.
- Fix future ingest by converting Efento local wall-clock timestamps from `Europe/Warsaw` to the correct UTC instant before writing to `temperature_logs`.
- Fix M02 rendering by formatting `recorded_at.toLocal()`.
- Do not modify historical rows.

## Implementation
- Add a shared Efento timezone utility for `Europe/Warsaw` wall-clock to UTC ISO conversion, with DST-aware offset resolution.
- Update `supabase/functions/efento-measurements-proxy/index.ts` to use the shared conversion instead of `Date.UTC(...)`.
- Update M02 presentation helpers/screens to render `recorded_at` in local time for charts and the 7-day table.

## Validation
- Unit-test the shared parser for winter and summer dates around `Europe/Warsaw`.
- Unit-test `TemperatureLog.fromJson` to confirm `recordedAt` is normalized to local time for display.
- Run targeted M02 tests and the new timezone parser tests.
