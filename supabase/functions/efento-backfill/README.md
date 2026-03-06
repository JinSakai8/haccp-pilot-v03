# efento-backfill

Backfill endpoint for Efento recovery path (Sprint 5 scope).

## Contract

1. Method: `POST`
2. Secret:
   - primary: header `X-HACCP-Backfill-Secret`
   - optional fallback: query `?secret=...` only when `EFENTO_ALLOW_QUERY_SECRET_FALLBACK=true`
     (disabled by default)
3. Request body (optional):
   - `measurementPointId` (integer, optional)
   - `includeBlocked` (boolean, default `false`; `true` enables manual retry for blocked points)
   - `from` (ISO-8601 UTC, optional)
   - `to` (ISO-8601 UTC, optional)
   - `overlapMinutes` (integer, default `15`)
   - `pageSize` (integer, default `200`, max `1000`)
   - `maxPages` (integer, default `20`, max `500`)
   - `dryRun` (boolean, default `false`)
4. Source writes:
   - `public.temperature_logs` (`source='efento_backfill'`)
   - `public.efento_health_events` (`source='efento_backfill'`)
5. Sync updates:
   - `public.efento_sync_state.last_successful_backfill_to`
   - `public.efento_sync_state.last_backfill_status`
6. Response:
   - summary counters (done/partial/failed, inserted/duplicates/errors)
   - blocked/access counters: `blockedSkippedCount`, `upstream403Count`
   - per-measurement-point outcomes
   - observability snapshot (queue, staleness, alerts)

## Required env vars

1. `EFENTO_BACKFILL_SECRET`
2. `EFENTO_API_TOKEN`
3. `EFENTO_API_MEASUREMENTS_URL`
4. `SUPABASE_URL`
5. `SUPABASE_SERVICE_ROLE_KEY`

Optional:
1. `EFENTO_BACKFILL_DEFAULT_LOOKBACK_HOURS` (default `6`)
2. `EFENTO_ALLOW_QUERY_SECRET_FALLBACK` (`false` by default)
3. `EFENTO_OBS_PENDING_ALERT_THRESHOLD` (default `25`)
4. `EFENTO_OBS_FAILED_ALERT_THRESHOLD` (default `5`)
5. `EFENTO_OBS_WEBHOOK_STALE_MINUTES` (default `30`)
6. `EFENTO_OBS_DATA_STALE_MINUTES` (default `45`)
7. `EFENTO_OBS_HEALTH_HOURLY_THRESHOLD` (default `20`)

## Deploy

```bash
supabase functions deploy efento-backfill --project-ref <PROJECT_REF> --no-verify-jwt
```

## Quick smoke tests

```bash
curl -i -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/efento-backfill" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Backfill-Secret: <EFENTO_BACKFILL_SECRET>" \
  --data '{"dryRun":true,"maxPages":2}'
```

```bash
curl -i -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/efento-backfill" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Backfill-Secret: wrong-secret" \
  --data '{"dryRun":true}'
```

```bash
curl -i -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/efento-backfill?secret=<EFENTO_BACKFILL_SECRET>" \
  -H "Content-Type: application/json" \
  --data '{"measurementPointId":123456789,"dryRun":true}'
```

Uwaga: test query-secret przejdzie tylko przy `EFENTO_ALLOW_QUERY_SECRET_FALLBACK=true`.
