# efento-scheduler

Scheduler/orchestrator endpoint for Efento pipeline (Sprint 5 scope).

## Contract

1. Method: `POST`
2. Secret:
   - primary: header `X-HACCP-Scheduler-Secret`
   - optional fallback: query `?secret=...` only when `EFENTO_ALLOW_QUERY_SECRET_FALLBACK=true`
     (disabled by default)
3. Request body (optional):
   - `dryRun` (boolean, default `false`)
   - `runWorker` (boolean, default `true`)
   - `runBackfill` (boolean, default `true`)
   - `includeObservability` (boolean, default `true`)
   - `workerBatchSize` (integer, default `100`)
   - `workerMeasurementPointId` (integer, optional)
   - `backfillMeasurementPointId` (integer, optional)
   - `backfillIncludeBlocked` (boolean, default `false`; forwarded as `includeBlocked` to backfill)
   - `backfillFrom` / `backfillTo` (ISO-8601 UTC, optional)
   - `backfillOverlapMinutes` (integer, default `15`)
   - `backfillPageSize` (integer, default `200`)
   - `backfillMaxPages` (integer, default `20`)
4. Behavior:
   - invokes `efento-worker`
   - invokes `efento-backfill`
   - returns invocation statuses + observability snapshot
5. Response semantics:
   - `ok` = pipeline health (`true` only when downstream pipelines are healthy)
   - `transportOk` = orchestration transport health (`false` when downstream HTTP/transport fails)
   - `pipelineOk` = alias of top-level pipeline status
   - `degraded=true` when `transportOk=true` but `ok=false`
   - `degradationReasons[]` contains endpoint-level reasons for pipeline degradation

HTTP status:
1. `200` when transport layer is healthy (`transportOk=true`)
2. `502` when any downstream invocation has transport failure (`transportOk=false`)

## Required env vars

1. `EFENTO_SCHEDULER_SECRET`
2. `EFENTO_WORKER_SECRET`
3. `EFENTO_BACKFILL_SECRET`
4. `SUPABASE_URL`
5. `SUPABASE_SERVICE_ROLE_KEY`

Optional:
1. `EFENTO_ALLOW_QUERY_SECRET_FALLBACK` (`false` by default)

## Deploy

```bash
supabase functions deploy efento-scheduler --project-ref <PROJECT_REF> --no-verify-jwt
```

## Quick smoke tests

```bash
curl -i -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/efento-scheduler" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Scheduler-Secret: <EFENTO_SCHEDULER_SECRET>" \
  --data '{"dryRun":true,"workerBatchSize":50,"backfillMaxPages":2}'
```

```bash
curl -i -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/efento-scheduler" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Scheduler-Secret: wrong-secret" \
  --data '{"dryRun":true}'
```

```bash
curl -i -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/efento-scheduler?secret=<EFENTO_SCHEDULER_SECRET>" \
  -H "Content-Type: application/json" \
  --data '{"dryRun":true,"runBackfill":false}'
```

Uwaga: test query-secret przejdzie tylko przy `EFENTO_ALLOW_QUERY_SECRET_FALLBACK=true`.
