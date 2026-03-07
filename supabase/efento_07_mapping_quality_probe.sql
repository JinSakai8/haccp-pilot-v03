-- Sprint 3 validation: mapping quality probe for measurementPointId=1032261
-- Usage:
-- 1) Run in SQL editor (staging/prod) after Sprint 3 migration.
-- 2) Export result tables as evidence to directives/26_Efento_10min_Sync_Implementation_Plan/.

-- 1) Mapping snapshot (target point + sensor + venue threshold context)
with params as (
  select 1032261::bigint as measurement_point_id
)
select
  p.measurement_point_id,
  m.sensor_id,
  m.is_active as mapping_is_active,
  m.device_serial_number,
  m.temperature_channel_number as expected_temperature_channel_number,
  m.measurement_point_name,
  m.updated_at as mapping_updated_at,
  s.name as sensor_name,
  s.zone_id,
  z.venue_id,
  coalesce(v.temp_threshold, 8.0) as venue_temp_threshold_c
from params p
left join public.efento_measurement_point_map m
  on m.measurement_point_id = p.measurement_point_id
left join public.sensors s
  on s.id = m.sensor_id
left join public.zones z
  on z.id = s.zone_id
left join public.venues v
  on v.id = z.venue_id;

-- 2) Temperature quality summary (last 24h, Efento-only sources)
with params as (
  select 1032261::bigint as measurement_point_id
),
target_map as (
  select
    p.measurement_point_id,
    m.sensor_id,
    m.is_active,
    m.temperature_channel_number,
    coalesce(v.temp_threshold, 8.0) as venue_temp_threshold_c
  from params p
  left join public.efento_measurement_point_map m
    on m.measurement_point_id = p.measurement_point_id
  left join public.sensors s
    on s.id = m.sensor_id
  left join public.zones z
    on z.id = s.zone_id
  left join public.venues v
    on v.id = z.venue_id
),
logs_24h as (
  select
    t.sensor_id,
    t.temperature_celsius,
    t.recorded_at,
    t.is_alert,
    t.source
  from public.temperature_logs t
  where t.recorded_at >= now() - interval '24 hours'
    and t.source in ('efento_webhook', 'efento_backfill')
)
select
  tm.measurement_point_id,
  tm.sensor_id,
  tm.is_active as mapping_is_active,
  tm.venue_temp_threshold_c as expected_alert_threshold_c,
  count(l.*) as total_points_24h,
  min(l.recorded_at) as first_point_at_utc,
  max(l.recorded_at) as last_point_at_utc,
  round(min(l.temperature_celsius)::numeric, 2) as min_temp_c,
  round(max(l.temperature_celsius)::numeric, 2) as max_temp_c,
  round(avg(l.temperature_celsius)::numeric, 2) as avg_temp_c,
  count(*) filter (where l.temperature_celsius < -40 or l.temperature_celsius > 30) as outside_hard_range_count,
  count(*) filter (where l.temperature_celsius > tm.venue_temp_threshold_c) as above_threshold_count,
  count(*) filter (where l.is_alert is true) as alert_rows_count,
  case
    when tm.sensor_id is null or tm.is_active is distinct from true then 'FAIL'
    when count(l.*) = 0 then 'FAIL'
    when count(*) filter (where l.temperature_celsius < -40 or l.temperature_celsius > 30) > 0 then 'PARTIAL'
    else 'PASS'
  end as temperature_quality_status
from target_map tm
left join logs_24h l
  on l.sensor_id = tm.sensor_id
group by
  tm.measurement_point_id,
  tm.sensor_id,
  tm.is_active,
  tm.venue_temp_threshold_c;

-- 3) Channel compliance summary from queue payload (last 24h)
with params as (
  select 1032261::bigint as measurement_point_id
),
target_map as (
  select
    p.measurement_point_id,
    m.sensor_id,
    m.is_active,
    m.temperature_channel_number
  from params p
  left join public.efento_measurement_point_map m
    on m.measurement_point_id = p.measurement_point_id
),
queue_24h as (
  select
    q.id,
    q.payload
  from params p
  join public.efento_ingest_queue q
    on q.measurement_point_id = p.measurement_point_id
  where q.received_at >= now() - interval '24 hours'
),
observed_channels as (
  select
    q.id as queue_id,
    upper(coalesce(nullif(btrim(ev ->> 'channelType'), ''), 'UNKNOWN')) as channel_type,
    case
      when coalesce(ev ->> 'channelNumber', '') ~ '^[0-9]+$'
        then (ev ->> 'channelNumber')::integer
      else null
    end as channel_number
  from queue_24h q
  cross join lateral jsonb_array_elements(
    case
      when jsonb_typeof(coalesce(q.payload -> 'measurementsEvents', '[]'::jsonb)) = 'array'
        then coalesce(q.payload -> 'measurementsEvents', '[]'::jsonb)
      else '[]'::jsonb
    end
  ) ev
),
channel_rollup as (
  select
    count(distinct oc.queue_id) filter (where oc.channel_type = 'TEMPERATURE') as frames_with_temperature_channel,
    count(distinct oc.queue_id) filter (
      where oc.channel_type = 'TEMPERATURE'
        and oc.channel_number is not null
        and oc.channel_number <> tm.temperature_channel_number
    ) as frames_with_channel_mismatch,
    array_remove(
      array_agg(
        distinct case when oc.channel_type = 'TEMPERATURE' then oc.channel_number else null end
      ),
      null
    ) as observed_temperature_channels
  from target_map tm
  left join observed_channels oc
    on true
)
select
  tm.measurement_point_id,
  tm.temperature_channel_number as expected_temperature_channel_number,
  coalesce(cr.frames_with_temperature_channel, 0) as frames_with_temperature_channel,
  coalesce(cr.frames_with_channel_mismatch, 0) as frames_with_channel_mismatch,
  coalesce(cr.observed_temperature_channels, array[]::integer[]) as observed_temperature_channels,
  case
    when tm.sensor_id is null or tm.is_active is distinct from true then 'FAIL'
    when coalesce(cr.frames_with_temperature_channel, 0) = 0 then 'PARTIAL'
    when coalesce(cr.frames_with_channel_mismatch, 0) > 0 then 'FAIL'
    else 'PASS'
  end as channel_compliance_status
from target_map tm
cross join channel_rollup cr;

-- 4) Overall probe decision (PASS / PARTIAL / FAIL)
with params as (
  select 1032261::bigint as measurement_point_id
),
target_map as (
  select
    p.measurement_point_id,
    m.sensor_id,
    m.is_active,
    m.temperature_channel_number
  from params p
  left join public.efento_measurement_point_map m
    on m.measurement_point_id = p.measurement_point_id
),
logs_24h as (
  select
    t.sensor_id,
    t.temperature_celsius,
    t.recorded_at
  from public.temperature_logs t
  where t.recorded_at >= now() - interval '24 hours'
    and t.source in ('efento_webhook', 'efento_backfill')
),
temperature_rollup as (
  select
    count(l.*) as total_points_24h,
    count(*) filter (where l.temperature_celsius < -40 or l.temperature_celsius > 30) as outside_hard_range_count
  from target_map tm
  left join logs_24h l
    on l.sensor_id = tm.sensor_id
),
queue_24h as (
  select
    q.id,
    q.payload
  from params p
  join public.efento_ingest_queue q
    on q.measurement_point_id = p.measurement_point_id
  where q.received_at >= now() - interval '24 hours'
),
observed_channels as (
  select
    q.id as queue_id,
    upper(coalesce(nullif(btrim(ev ->> 'channelType'), ''), 'UNKNOWN')) as channel_type,
    case
      when coalesce(ev ->> 'channelNumber', '') ~ '^[0-9]+$'
        then (ev ->> 'channelNumber')::integer
      else null
    end as channel_number
  from queue_24h q
  cross join lateral jsonb_array_elements(
    case
      when jsonb_typeof(coalesce(q.payload -> 'measurementsEvents', '[]'::jsonb)) = 'array'
        then coalesce(q.payload -> 'measurementsEvents', '[]'::jsonb)
      else '[]'::jsonb
    end
  ) ev
),
channel_rollup as (
  select
    count(distinct oc.queue_id) filter (where oc.channel_type = 'TEMPERATURE') as frames_with_temperature_channel,
    count(distinct oc.queue_id) filter (
      where oc.channel_type = 'TEMPERATURE'
        and oc.channel_number is not null
        and oc.channel_number <> tm.temperature_channel_number
    ) as frames_with_channel_mismatch
  from target_map tm
  left join observed_channels oc
    on true
)
select
  tm.measurement_point_id,
  tm.sensor_id,
  tm.is_active as mapping_is_active,
  tr.total_points_24h,
  tr.outside_hard_range_count,
  cr.frames_with_temperature_channel,
  cr.frames_with_channel_mismatch,
  case
    when tm.sensor_id is null or tm.is_active is distinct from true then 'FAIL'
    when coalesce(cr.frames_with_channel_mismatch, 0) > 0 then 'FAIL'
    when coalesce(tr.total_points_24h, 0) = 0 then 'PARTIAL'
    when coalesce(tr.outside_hard_range_count, 0) > 0 then 'PARTIAL'
    when coalesce(cr.frames_with_temperature_channel, 0) = 0 then 'PARTIAL'
    else 'PASS'
  end as probe_decision,
  concat_ws(
    '; ',
    case when tm.sensor_id is null then 'mapping_missing' end,
    case when tm.is_active is distinct from true then 'mapping_inactive' end,
    case when coalesce(cr.frames_with_channel_mismatch, 0) > 0 then 'channel_mismatch_detected' end,
    case when coalesce(tr.total_points_24h, 0) = 0 then 'no_efento_points_last_24h' end,
    case when coalesce(tr.outside_hard_range_count, 0) > 0 then 'outside_hard_range_detected' end,
    case when coalesce(cr.frames_with_temperature_channel, 0) = 0 then 'no_temperature_channel_seen_in_queue_24h' end
  ) as decision_notes
from target_map tm
cross join temperature_rollup tr
cross join channel_rollup cr;

