-- Sprint 6 (Efento) E2E release gate validation
-- Usage: run manually against staging/production after Sprint 6 runtime tests.
-- Safe by default: script runs in a transaction and ends with ROLLBACK.

begin;

do $$
declare
  v_cron_job_relation_exists boolean;
  v_cron_job_run_details_relation_exists boolean;
  v_scheduler_job_match_count integer;
  v_scheduler_job_id bigint;
  v_recent_succeeded_runs integer;
  v_recent_non_succeeded_runs integer;
  v_duplicate_temperature_source_ref integer;
  v_duplicate_health_source_ref integer;
  v_missing_temperature_source_ref integer;
  v_missing_health_source_ref integer;
  v_unmapped_recent_measurement_points integer;
  v_stuck_processing_rows integer;
  v_recent_failed_rows integer;
  v_future_temperature_rows integer;
  v_future_health_rows integer;
begin
  -- 0) Runtime scheduler cadence and cron health checks.
  select to_regclass('cron.job') is not null
    into v_cron_job_relation_exists;

  if not v_cron_job_relation_exists then
    raise exception
      'Gate FAIL: pg_cron relation cron.job is missing.';
  end if;

  select to_regclass('cron.job_run_details') is not null
    into v_cron_job_run_details_relation_exists;

  if not v_cron_job_run_details_relation_exists then
    raise exception
      'Gate FAIL: pg_cron relation cron.job_run_details is missing.';
  end if;

  select count(*), max(j.jobid)::bigint
    into v_scheduler_job_match_count, v_scheduler_job_id
  from cron.job j
  where j.jobname = 'efento_scheduler_every_10_min'
    and j.active is true
    and j.schedule = '*/10 * * * *';

  if v_scheduler_job_match_count = 0 then
    raise exception
      'Gate FAIL: active cron job efento_scheduler_every_10_min with schedule */10 is missing.';
  end if;

  select count(*)
    into v_recent_succeeded_runs
  from cron.job_run_details d
  where d.jobid = v_scheduler_job_id
    and d.status = 'succeeded'
    and d.start_time >= now() - interval '30 minutes';

  if v_recent_succeeded_runs = 0 then
    raise exception
      'Gate FAIL: no succeeded cron runs for efento_scheduler_every_10_min in the last 30 minutes.';
  end if;

  select count(*)
    into v_recent_non_succeeded_runs
  from cron.job_run_details d
  where d.jobid = v_scheduler_job_id
    and d.status <> 'succeeded'
    and d.start_time >= now() - interval '30 minutes';

  if v_recent_non_succeeded_runs > 0 then
    raise exception
      'Gate FAIL: non-succeeded cron runs for efento_scheduler_every_10_min found in the last 30 minutes (count=%).',
      v_recent_non_succeeded_runs;
  end if;

  -- 1) Dedupe integrity for temperature_logs (Efento sources only).
  select count(*)
    into v_duplicate_temperature_source_ref
  from (
    select t.source_ref
    from public.temperature_logs t
    where t.source in ('efento_webhook', 'efento_backfill')
      and t.source_ref is not null
    group by t.source_ref
    having count(*) > 1
  ) duplicates;

  if v_duplicate_temperature_source_ref > 0 then
    raise exception
      'Gate FAIL: duplicate source_ref in temperature_logs for Efento sources (count=%).',
      v_duplicate_temperature_source_ref;
  end if;

  -- 2) Dedupe integrity for efento_health_events.
  select count(*)
    into v_duplicate_health_source_ref
  from (
    select h.source_ref
    from public.efento_health_events h
    where h.source in ('efento_webhook', 'efento_backfill')
      and h.source_ref is not null
    group by h.source_ref
    having count(*) > 1
  ) duplicates;

  if v_duplicate_health_source_ref > 0 then
    raise exception
      'Gate FAIL: duplicate source_ref in efento_health_events (count=%).',
      v_duplicate_health_source_ref;
  end if;

  -- 3) Contract integrity: source_ref must exist for Efento rows.
  select count(*)
    into v_missing_temperature_source_ref
  from public.temperature_logs t
  where t.source in ('efento_webhook', 'efento_backfill')
    and coalesce(nullif(trim(t.source_ref), ''), '') = '';

  if v_missing_temperature_source_ref > 0 then
    raise exception
      'Gate FAIL: temperature_logs rows with Efento source and missing source_ref (count=%).',
      v_missing_temperature_source_ref;
  end if;

  select count(*)
    into v_missing_health_source_ref
  from public.efento_health_events h
  where h.source in ('efento_webhook', 'efento_backfill')
    and coalesce(nullif(trim(h.source_ref), ''), '') = '';

  if v_missing_health_source_ref > 0 then
    raise exception
      'Gate FAIL: efento_health_events rows with Efento source and missing source_ref (count=%).',
      v_missing_health_source_ref;
  end if;

  -- 4) Mapping coverage for measurement points seen recently in queue.
  select count(*)
    into v_unmapped_recent_measurement_points
  from (
    select distinct q.measurement_point_id
    from public.efento_ingest_queue q
    left join public.efento_measurement_point_map m
      on m.measurement_point_id = q.measurement_point_id
     and m.is_active is true
    where q.received_at >= now() - interval '24 hours'
      and m.measurement_point_id is null
  ) unmapped_points;

  if v_unmapped_recent_measurement_points > 0 then
    raise exception
      'Gate FAIL: queue contains recent measurement points without active mapping (count=%).',
      v_unmapped_recent_measurement_points;
  end if;

  -- 5) Worker health: no stuck processing records.
  select count(*)
    into v_stuck_processing_rows
  from public.efento_ingest_queue q
  where q.status = 'processing'
    and q.locked_at is not null
    and q.locked_at <= now() - interval '15 minutes';

  if v_stuck_processing_rows > 0 then
    raise exception
      'Gate FAIL: queue has stuck processing rows older than 15 minutes (count=%).',
      v_stuck_processing_rows;
  end if;

  -- 6) No recent failed queue rows after stabilization window.
  select count(*)
    into v_recent_failed_rows
  from public.efento_ingest_queue q
  where q.status = 'failed'
    and q.updated_at >= now() - interval '24 hours';

  if v_recent_failed_rows > 0 then
    raise exception
      'Gate FAIL: queue has failed rows in the last 24 hours (count=%).',
      v_recent_failed_rows;
  end if;

  -- 7) UTC sanity: no Efento timestamps significantly in the future.
  select count(*)
    into v_future_temperature_rows
  from public.temperature_logs t
  where t.source in ('efento_webhook', 'efento_backfill')
    and t.recorded_at > now() + interval '5 minutes';

  if v_future_temperature_rows > 0 then
    raise exception
      'Gate FAIL: temperature_logs has Efento rows recorded in the future (count=%).',
      v_future_temperature_rows;
  end if;

  select count(*)
    into v_future_health_rows
  from public.efento_health_events h
  where h.source in ('efento_webhook', 'efento_backfill')
    and h.event_timestamp > now() + interval '5 minutes';

  if v_future_health_rows > 0 then
    raise exception
      'Gate FAIL: efento_health_events has rows in the future (count=%).',
      v_future_health_rows;
  end if;

  raise notice 'Gate PASS: Efento Sprint 6 SQL release checks are green.';
end;
$$ language plpgsql;

rollback;
