# efento-measurements-proxy

Proxy for `efento-backfill` that adapts Efento Cloud measurements endpoint to the frame contract expected by backfill.

## Why

`efento-backfill` expects:
1. Query params: `measurementPointId`, `from`, `to` in ISO format.
2. Payload with `items[]` frames containing:
   - `measurementPointId`
   - `deviceSerialNumber`
   - `firstMeasurementTimestamp`
   - `lastMeasurementTimestamp`
   - `measurementsEvents[]`

Efento Cloud endpoint uses:
1. Path parameter `/measurement-points/{id}/measurements`.
2. Datetime format `yyyy-MM-dd HH:mm:ss`.
3. Payload rooted in `measurements[]`.

This proxy normalizes request and response so backfill can use real Efento API without changing existing backfill logic.

## Runtime contract

1. Method: `GET`
2. Required query params:
   - `measurementPointId`
   - `from` (ISO-8601 UTC)
   - `to` (ISO-8601 UTC)
3. Required headers:
   - `authorization` or `x-efento-api-token` with Efento API token
4. Output:
   - `{ items: [...], nextPageToken: null, proxied: true, ... }`

## Deploy

```bash
supabase functions deploy efento-measurements-proxy --project-ref <PROJECT_REF> --no-verify-jwt
```
