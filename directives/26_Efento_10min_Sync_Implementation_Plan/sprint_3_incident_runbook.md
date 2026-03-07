# Sprint 3 Incident Runbook

Projekt: `gzjibisiofkcnvsqqbsc`  
Wersja: `2026-03-06`

## 1. Cel
Zapewnic procedury od diagnozy do recovery dla krytycznych incydentow pipeline Efento.

## 2. Triage (kolejnosc)
1. Potwierdz status funkcji:
   - `efento-webhook`,
   - `efento-worker`,
   - `efento-backfill`,
   - `efento-scheduler`.
2. Sprawdz metryki kolejki:
   - `pending`, `processing`, `failed`,
   - `failed_last_24h`,
   - `processing_stuck_over_15m`.
3. Sprawdz staleness:
   - `minutesSinceLastWebhook`,
   - `minutesSinceLastData`.
   - uwaga: punkty `upstream_access_state='blocked'` sa wykluczane z `WEBHOOK_STALE`/`DATA_STALE`.
4. Sprawdz mapping coverage:
   - `missing_mapping_count`.
   - `blocked_measurement_points_count`.
5. Sprawdz integralnosc:
   - duplicate `source_ref`.

## 3. Scenariusz A - Brak nowych temperatur
Objawy:
1. rosnace `minutesSinceLastData`,
2. brak przyrostu `temperature_logs`,
3. alert `DATA_STALE` / `WEBHOOK_STALE`.
4. mozliwy alert `UPSTREAM_BLOCKED_POINTS` (warning).

Dzialania:
1. Manual trigger schedulera:
```bash
curl -i -X POST "https://<project-ref>.supabase.co/functions/v1/efento-scheduler" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Scheduler-Secret: <SECRET>" \
  --data '{"dryRun":false,"runWorker":true,"runBackfill":true,"includeObservability":true,"workerBatchSize":100}'
```
2. Jesli stale pozostaje:
   - uruchom selektywny backfill (Scenariusz E).
3. Potwierdz recovery:
   - spadek `minutesSinceLastData`,
   - brak nowych `failed` (z wyjatkiem punktow stale blokowanych upstream).

## 4. Scenariusz B - Stale rosnacy backlog
Objawy:
1. `pendingCount` rosnie i nie schodzi po cyklach,
2. mozliwe `processing_stuck_over_15m > 0`.

Dzialania:
1. Uruchom worker:
```bash
curl -i -X POST "https://<project-ref>.supabase.co/functions/v1/efento-worker" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Worker-Secret: <SECRET>" \
  --data '{"batchSize":200,"dryRun":false}'
```
2. Uruchom scheduler recovery:
```bash
curl -i -X POST "https://<project-ref>.supabase.co/functions/v1/efento-scheduler" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Scheduler-Secret: <SECRET>" \
  --data '{"dryRun":false,"runWorker":true,"runBackfill":true,"workerBatchSize":200}'
```
3. Jesli backlog nadal rosnie:
   - eskalacja P1 do backend ownera.

## 5. Scenariusz C - Failed rows spike
Objawy:
1. `failed_last_24h` przekracza prog,
2. `QUEUE_FAILED_BACKLOG` alert.

Dzialania:
1. Zidentyfikuj dominujacy `last_error`.
2. Dla bledow transient:
   - rerun worker/backfill.
3. Dla bledow upstream `403`:
   - punkt powinien automatycznie przejsc do `upstream_access_state='blocked'`,
   - potwierdz wpis `upstream_access_last_checked_at` i `upstream_access_last_error`,
   - traktuj jako dependency incident i uruchom monitorowanie warning (`UPSTREAM_BLOCKED_POINTS`),
   - nie eskaluj do P1/P2 tylko z powodu stale blocked points.

## 6. Scenariusz D - Brak mapowan punktow
Objawy:
1. `missing_mapping_count > 0`,
2. worker/backfill nie procesuje czesci punktow.

Dzialania:
1. Zweryfikuj `efento_measurement_point_map` dla brakujacych punktow.
2. Dodaj/aktywuj mapowanie.
3. Uruchom targeted backfill po remap.

## 7. Procedura E - Selektywny backfill
Cel:
1. domkniecie luki dla konkretnego `measurementPointId` i okna czasu.

Komenda:
```bash
curl -i -X POST "https://<project-ref>.supabase.co/functions/v1/efento-backfill" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Backfill-Secret: <SECRET>" \
  --data '{"measurementPointId":123456789,"from":"2026-03-06T08:00:00Z","to":"2026-03-06T10:00:00Z","dryRun":false,"overlapMinutes":30,"maxPages":20}'
```

## 8. Procedura F - Retry punktu blocked
Cel:
1. manualny retry punktu oznaczonego `blocked` po potwierdzeniu odblokowania po stronie Efento.

Komenda (preferowane przez scheduler):
```bash
curl -i -X POST "https://<project-ref>.supabase.co/functions/v1/efento-scheduler" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Scheduler-Secret: <SECRET>" \
  --data '{"dryRun":false,"runWorker":false,"runBackfill":true,"backfillIncludeBlocked":true,"backfillMeasurementPointId":123456789,"backfillMaxPages":20}'
```

Komenda (bezposrednio backfill):
```bash
curl -i -X POST "https://<project-ref>.supabase.co/functions/v1/efento-backfill" \
  -H "Content-Type: application/json" \
  -H "X-HACCP-Backfill-Secret: <SECRET>" \
  --data '{"measurementPointId":123456789,"includeBlocked":true,"dryRun":false,"maxPages":20}'
```

Walidacja:
1. po sukcesie punkt wraca do `upstream_access_state='ok'`,
2. `upstream_access_last_error` jest czyszczony,
3. alert `UPSTREAM_BLOCKED_POINTS` maleje lub znika.

## 9. Walidacja po incydencie
Minimalny gate:
1. `processing_stuck_over_15m = 0`,
2. `failed_last_24h` wraca do poziomu bazowego,
3. `duplicate_source_ref_temperature = 0`,
4. `duplicate_source_ref_health = 0`,
5. `missing_mapping_count = 0`,
6. `cron.job_run_details` ma kolejne runy `succeeded`,
7. stale blocked points sa sklasyfikowane jako warning (`UPSTREAM_BLOCKED_POINTS`) i maja ownera.

## 10. Postmortem format (template)
1. `Incident ID`:
2. `Start/End (UTC)`:
3. `Severity`:
4. `Primary metric trigger`:
5. `Impact` (zakres danych/moduly):
6. `Root cause`:
7. `Timeline` (T0/T1/T2...):
8. `Recovery actions`:
9. `Validation evidence`:
10. `Follow-up actions` (owner + due date):
11. `Preventive changes`:

## 11. Drill evidence Sprint 3
1. `sprint_3_scheduler_drill_http_status_2026-03-06.txt` -> `200`
2. `sprint_3_scheduler_drill_response_2026-03-06.json` -> worker/backfill invocations `HTTP 200`.
