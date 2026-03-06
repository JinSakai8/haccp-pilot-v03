# Sprint 3 Daily Ops Checklist

Data wejscia: `2026-03-06`  
Cel: dzienna kontrola zdrowia pipeline Efento.

## 1. Start-of-day checks (kolejnosc)
- [ ] Sprawdz status funkcji runtime (`efento-webhook`, `efento-worker`, `efento-backfill`, `efento-scheduler`).
- [ ] Sprawdz job `efento_scheduler_every_10_min` (`active=true`, `schedule='*/10 * * * *'`).
- [ ] Sprawdz ostatnie runy `cron.job_run_details` (>=1 `succeeded` w ostatnich 30 min i brak `status <> succeeded` w ostatnich 30 min).
- [ ] Sprawdz queue (`pending`, `processing`, `failed`).
- [ ] Sprawdz `failed_last_24h`.
- [ ] Sprawdz `processing_stuck_over_15m`.
- [ ] Sprawdz staleness (`minutesSinceLastWebhook`, `minutesSinceLastData`) dla punktow nie-`blocked`.
- [ ] Sprawdz duplicate `source_ref` (temperature + health).
- [ ] Sprawdz `missing_mapping_count`.
- [ ] Sprawdz `blocked_measurement_points_count` + alert `UPSTREAM_BLOCKED_POINTS`.

## 2. Daily SQL pack
```sql
-- Scheduler cron config (must be active with */10 cadence)
select jobid, jobname, schedule, active
from cron.job
where jobname = 'efento_scheduler_every_10_min';

-- Scheduler cron run health (last 30 minutes)
with scheduler_job as (
  select jobid
  from cron.job
  where jobname = 'efento_scheduler_every_10_min'
    and active is true
    and schedule = '*/10 * * * *'
  order by jobid desc
  limit 1
)
select
  count(*) filter (where d.status = 'succeeded') as succeeded_last_30m,
  count(*) filter (where d.status <> 'succeeded') as non_succeeded_last_30m
from cron.job_run_details d
join scheduler_job j on j.jobid = d.jobid
where d.start_time >= now() - interval '30 minutes';

-- Queue status
select status, count(*)
from public.efento_ingest_queue
group by status
order by status;

-- Failed / 24h + processing stuck > 15m
select
  count(*) filter (where status='failed' and updated_at >= now() - interval '24 hour') as failed_last_24h,
  count(*) filter (where status='processing' and locked_at < now() - interval '15 minute') as processing_stuck_over_15m
from public.efento_ingest_queue;

-- Staleness by measurement point (exclude upstream blocked points)
with active_points as (
  select distinct measurement_point_id
  from public.efento_measurement_point_map
  where is_active = true
    and coalesce(upstream_access_state, 'unknown') <> 'blocked'
)
select
  p.measurement_point_id,
  round(extract(epoch from (now() - s.last_webhook_received_at))/60.0, 1) as minutes_since_last_webhook,
  round(extract(epoch from (
    now() - greatest(
      coalesce(s.last_successful_expand_to, to_timestamp(0)),
      coalesce(s.last_successful_backfill_to, to_timestamp(0))
    )
  ))/60.0, 1) as minutes_since_last_data,
  s.last_backfill_status
from active_points p
left join public.efento_sync_state s on s.measurement_point_id = p.measurement_point_id
order by p.measurement_point_id;

-- Upstream blocked points
select
  measurement_point_id,
  upstream_access_state,
  upstream_access_last_checked_at,
  upstream_access_last_error
from public.efento_measurement_point_map
where is_active = true
  and upstream_access_state = 'blocked'
order by measurement_point_id;

-- Duplicate source_ref
select source_ref, count(*) as duplicate_count
from public.temperature_logs
where source in ('efento_webhook','efento_backfill') and source_ref is not null
group by source_ref
having count(*) > 1
order by duplicate_count desc;
```

## 3. Pass criteria (daily)
1. Job `efento_scheduler_every_10_min` istnieje, `active=true`, `schedule='*/10 * * * *'`.
2. `cron.job_run_details`: `succeeded_last_30m >= 1` i `non_succeeded_last_30m = 0`.
3. `processing_stuck_over_15m = 0`.
4. `failed_last_24h < 5`.
5. `duplicate source_ref` brak.
6. `missing_mapping_count = 0`.
7. `stale_data_points_count` nie wzrasta dzien-do-dnia (dla punktow nie-`blocked`).
8. `blocked_measurement_points_count` ma przypisanego ownera i status upstream.

## 4. Fail handling
1. Dowolny fail -> uruchom `sprint_3_incident_runbook.md`.
2. Dla P1 eskalacja natychmiastowa (on-call + ticket).
3. Po recovery wykonaj ponowny SQL pack i zapisz evidence.

## 5. Dzienny log operacyjny (minimum)
1. `date_utc`
2. `operator`
3. `queue_summary`
4. `failed_last_24h`
5. `staleness_summary`
6. `actions_taken`
7. `status` (`GREEN`/`AMBER`/`RED`)
