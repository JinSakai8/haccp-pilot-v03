import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";

type QueueStatus = "pending" | "processing" | "failed";
type UpstreamAccessState = "unknown" | "ok" | "blocked";

type QueueRow = {
  measurement_point_id: number | null;
  status: QueueStatus;
  received_at: string;
};

type SyncStateRow = {
  measurement_point_id: number;
  last_webhook_received_at: string | null;
  last_successful_expand_to: string | null;
  last_successful_backfill_to: string | null;
  last_backfill_status: "ok" | "partial" | "failed" | "dry_run" | null;
};

export type AlertThresholds = {
  pendingThreshold: number;
  failedThreshold: number;
  webhookStaleMinutes: number;
  dataStaleMinutes: number;
  healthHourlyThreshold: number;
};

export type ObservabilityAlert = {
  code:
    | "QUEUE_PENDING_BACKLOG"
    | "QUEUE_FAILED_BACKLOG"
    | "WEBHOOK_STALE"
    | "DATA_STALE"
    | "UPSTREAM_BLOCKED_POINTS"
    | "HEALTH_SPIKE";
  severity: "warning" | "critical";
  message: string;
};

export type MeasurementPointHealth = {
  measurementPointId: number;
  upstreamAccessState: UpstreamAccessState;
  pendingCount: number;
  processingCount: number;
  failedCount: number;
  minutesSinceLastWebhook: number | null;
  minutesSinceLastData: number | null;
  lastBackfillStatus: "ok" | "partial" | "failed" | "dry_run" | null;
};

export type BlockedMeasurementPoint = {
  measurementPointId: number;
  upstreamAccessLastCheckedAt: string | null;
  upstreamAccessLastError: string | null;
};

export type ObservabilitySnapshot = {
  generatedAt: string;
  queue: {
    pendingCount: number;
    processingCount: number;
    failedCount: number;
    oldestPendingAt: string | null;
    oldestPendingMinutes: number | null;
  };
  healthHourlyCount: number;
  measurementPoints: MeasurementPointHealth[];
  blockedMeasurementPoints: {
    count: number;
    items: BlockedMeasurementPoint[];
  };
  alerts: ObservabilityAlert[];
};

function parseTimestampMs(value: string | null | undefined): number | null {
  if (!value || typeof value !== "string") {
    return null;
  }

  const parsed = new Date(value).getTime();
  if (Number.isNaN(parsed)) {
    return null;
  }

  return parsed;
}

function minutesBetween(fromMs: number, toMs: number): number {
  return Math.floor((toMs - fromMs) / 60000);
}

function parseEnvInt(
  rawValue: string | undefined,
  defaultValue: number,
  minValue: number,
  maxValue: number,
): number {
  if (!rawValue) {
    return defaultValue;
  }

  const parsed = Number.parseInt(rawValue, 10);
  if (!Number.isFinite(parsed)) {
    return defaultValue;
  }

  return Math.max(minValue, Math.min(maxValue, parsed));
}

function maxTimestampMs(
  values: Array<string | null | undefined>,
): number | null {
  let maxMs: number | null = null;
  for (const value of values) {
    const parsed = parseTimestampMs(value);
    if (parsed === null) {
      continue;
    }
    if (maxMs === null || parsed > maxMs) {
      maxMs = parsed;
    }
  }
  return maxMs;
}

function minTimestampIso(values: string[]): string | null {
  let minMs: number | null = null;
  let minIso: string | null = null;

  for (const value of values) {
    const parsed = parseTimestampMs(value);
    if (parsed === null) {
      continue;
    }
    if (minMs === null || parsed < minMs) {
      minMs = parsed;
      minIso = new Date(parsed).toISOString();
    }
  }

  return minIso;
}

function isMissingUpstreamAccessStateColumnError(
  error: { message?: string } | null | undefined,
): boolean {
  if (!error || typeof error.message !== "string") {
    return false;
  }
  const message = error.message.toLowerCase();
  return message.includes(
    "efento_measurement_point_map.upstream_access_state",
  ) &&
    message.includes("does not exist");
}

function upsertQueueAccumulator(
  map: Map<number, { pending: number; processing: number; failed: number }>,
  measurementPointId: number,
  status: QueueStatus,
): void {
  const existing = map.get(measurementPointId) ??
    { pending: 0, processing: 0, failed: 0 };
  if (status === "pending") {
    existing.pending += 1;
  } else if (status === "processing") {
    existing.processing += 1;
  } else if (status === "failed") {
    existing.failed += 1;
  }
  map.set(measurementPointId, existing);
}

export function loadAlertThresholdsFromEnv(): AlertThresholds {
  return {
    pendingThreshold: parseEnvInt(
      Deno.env.get("EFENTO_OBS_PENDING_ALERT_THRESHOLD"),
      25,
      1,
      50000,
    ),
    failedThreshold: parseEnvInt(
      Deno.env.get("EFENTO_OBS_FAILED_ALERT_THRESHOLD"),
      5,
      1,
      50000,
    ),
    webhookStaleMinutes: parseEnvInt(
      Deno.env.get("EFENTO_OBS_WEBHOOK_STALE_MINUTES"),
      30,
      1,
      7 * 24 * 60,
    ),
    dataStaleMinutes: parseEnvInt(
      Deno.env.get("EFENTO_OBS_DATA_STALE_MINUTES"),
      45,
      1,
      7 * 24 * 60,
    ),
    healthHourlyThreshold: parseEnvInt(
      Deno.env.get("EFENTO_OBS_HEALTH_HOURLY_THRESHOLD"),
      20,
      1,
      50000,
    ),
  };
}

export async function buildObservabilitySnapshot(params: {
  supabase: SupabaseClient;
  thresholds: AlertThresholds;
  nowIso?: string;
}): Promise<ObservabilitySnapshot> {
  const nowIso = params.nowIso ?? new Date().toISOString();
  const nowMs = parseTimestampMs(nowIso) ?? Date.now();

  const queueResult = await params.supabase
    .from("efento_ingest_queue")
    .select("measurement_point_id,status,received_at")
    .in("status", ["pending", "processing", "failed"]);

  if (queueResult.error) {
    throw new Error(
      `observability queue query failed: ${queueResult.error.message}`,
    );
  }

  const syncResult = await params.supabase
    .from("efento_sync_state")
    .select(
      "measurement_point_id,last_webhook_received_at,last_successful_expand_to,last_successful_backfill_to,last_backfill_status",
    );

  if (syncResult.error) {
    throw new Error(
      `observability sync_state query failed: ${syncResult.error.message}`,
    );
  }

  type MappingRow = {
    measurement_point_id: number;
    is_active: boolean;
    upstream_access_state: UpstreamAccessState | null;
    upstream_access_last_checked_at: string | null;
    upstream_access_last_error: string | null;
  };
  let mappingRows: MappingRow[] = [];

  const mappingsWithUpstreamResult = await params.supabase
    .from("efento_measurement_point_map")
    .select(
      "measurement_point_id,is_active,upstream_access_state,upstream_access_last_checked_at,upstream_access_last_error",
    )
    .eq("is_active", true);

  if (
    mappingsWithUpstreamResult.error &&
    isMissingUpstreamAccessStateColumnError(mappingsWithUpstreamResult.error)
  ) {
    const mappingsLegacyResult = await params.supabase
      .from("efento_measurement_point_map")
      .select("measurement_point_id,is_active")
      .eq("is_active", true);

    if (mappingsLegacyResult.error) {
      throw new Error(
        `observability measurement map query failed: ${mappingsLegacyResult.error.message}`,
      );
    }

    mappingRows = ((mappingsLegacyResult.data ?? []) as Array<{
      measurement_point_id: number;
      is_active: boolean;
    }>).map((row) => ({
      measurement_point_id: row.measurement_point_id,
      is_active: row.is_active,
      upstream_access_state: "unknown",
      upstream_access_last_checked_at: null,
      upstream_access_last_error: null,
    }));
  } else if (mappingsWithUpstreamResult.error) {
    throw new Error(
      `observability measurement map query failed: ${mappingsWithUpstreamResult.error.message}`,
    );
  } else {
    mappingRows = (mappingsWithUpstreamResult.data ?? []) as MappingRow[];
  }

  const hourlyFromIso = new Date(nowMs - 60 * 60 * 1000).toISOString();
  const healthResult = await params.supabase
    .from("efento_health_events")
    .select("id", { head: true, count: "exact" })
    .gte("event_timestamp", hourlyFromIso);

  if (healthResult.error) {
    throw new Error(
      `observability health query failed: ${healthResult.error.message}`,
    );
  }

  const queueRows = (queueResult.data ?? []) as QueueRow[];
  const syncRows = (syncResult.data ?? []) as SyncStateRow[];
  const pendingCount =
    queueRows.filter((row) => row.status === "pending").length;
  const processingCount =
    queueRows.filter((row) => row.status === "processing").length;
  const failedCount = queueRows.filter((row) => row.status === "failed").length;

  const oldestPendingAt = minTimestampIso(
    queueRows
      .filter((row) => row.status === "pending")
      .map((row) => row.received_at),
  );
  const oldestPendingMinutes = oldestPendingAt
    ? minutesBetween(parseTimestampMs(oldestPendingAt) ?? nowMs, nowMs)
    : null;

  const queueByMeasurementPoint = new Map<
    number,
    { pending: number; processing: number; failed: number }
  >();
  for (const row of queueRows) {
    if (typeof row.measurement_point_id !== "number") {
      continue;
    }
    upsertQueueAccumulator(
      queueByMeasurementPoint,
      row.measurement_point_id,
      row.status,
    );
  }

  const syncByMeasurementPoint = new Map<number, SyncStateRow>();
  for (const row of syncRows) {
    syncByMeasurementPoint.set(row.measurement_point_id, row);
  }

  const upstreamStatePriority: Record<UpstreamAccessState, number> = {
    blocked: 3,
    ok: 2,
    unknown: 1,
  };
  const upstreamStateByMeasurementPoint = new Map<
    number,
    UpstreamAccessState
  >();
  for (const row of mappingRows) {
    const state = row.upstream_access_state === "blocked" ||
        row.upstream_access_state === "ok"
      ? row.upstream_access_state
      : "unknown";
    const existing = upstreamStateByMeasurementPoint.get(
      row.measurement_point_id,
    );
    if (
      !existing ||
      upstreamStatePriority[state] > upstreamStatePriority[existing]
    ) {
      upstreamStateByMeasurementPoint.set(row.measurement_point_id, state);
    }
  }

  const blockedMeasurementPoints: BlockedMeasurementPoint[] = mappingRows
    .filter((row) => row.upstream_access_state === "blocked")
    .map((row) => ({
      measurementPointId: row.measurement_point_id,
      upstreamAccessLastCheckedAt: row.upstream_access_last_checked_at ?? null,
      upstreamAccessLastError: row.upstream_access_last_error ?? null,
    }))
    .sort((a, b) => a.measurementPointId - b.measurementPointId);

  const stalenessEligibleMeasurementPointIds = new Set<number>(
    mappingRows
      .filter((row) => row.upstream_access_state !== "blocked")
      .map((row) => row.measurement_point_id),
  );

  const allMeasurementPointIds = new Set<number>();
  for (const row of syncRows) {
    allMeasurementPointIds.add(row.measurement_point_id);
  }
  for (const row of mappingRows) {
    allMeasurementPointIds.add(row.measurement_point_id);
  }

  const measurementPoints: MeasurementPointHealth[] = [];
  for (
    const measurementPointId of Array.from(allMeasurementPointIds.values())
  ) {
    const row = syncByMeasurementPoint.get(measurementPointId);
    const queueStats = queueByMeasurementPoint.get(measurementPointId) ?? {
      pending: 0,
      processing: 0,
      failed: 0,
    };

    const latestDataMs = maxTimestampMs([
      row?.last_successful_expand_to ?? null,
      row?.last_successful_backfill_to ?? null,
    ]);
    const lastWebhookMs = parseTimestampMs(
      row?.last_webhook_received_at ?? null,
    );

    measurementPoints.push({
      measurementPointId,
      upstreamAccessState:
        upstreamStateByMeasurementPoint.get(measurementPointId) ?? "unknown",
      pendingCount: queueStats.pending,
      processingCount: queueStats.processing,
      failedCount: queueStats.failed,
      minutesSinceLastWebhook: lastWebhookMs === null
        ? null
        : minutesBetween(lastWebhookMs, nowMs),
      minutesSinceLastData: latestDataMs === null
        ? null
        : minutesBetween(latestDataMs, nowMs),
      lastBackfillStatus: row?.last_backfill_status ?? null,
    });
  }

  measurementPoints.sort((a, b) => a.measurementPointId - b.measurementPointId);

  const latestWebhookMs = maxTimestampMs(
    syncRows
      .filter((row) =>
        stalenessEligibleMeasurementPointIds.has(row.measurement_point_id)
      )
      .map((row) => row.last_webhook_received_at),
  );
  const minutesSinceGlobalWebhook = latestWebhookMs === null
    ? null
    : minutesBetween(latestWebhookMs, nowMs);

  const staleDataPoints = measurementPoints.filter(
    (point) =>
      stalenessEligibleMeasurementPointIds.has(point.measurementPointId) &&
      (point.minutesSinceLastData === null ||
        point.minutesSinceLastData >= params.thresholds.dataStaleMinutes),
  );

  const alerts: ObservabilityAlert[] = [];
  if (pendingCount >= params.thresholds.pendingThreshold) {
    alerts.push({
      code: "QUEUE_PENDING_BACKLOG",
      severity: "warning",
      message:
        `Queue pending backlog threshold reached: pending=${pendingCount}, ` +
        `threshold=${params.thresholds.pendingThreshold}.`,
    });
  }

  if (failedCount >= params.thresholds.failedThreshold) {
    alerts.push({
      code: "QUEUE_FAILED_BACKLOG",
      severity: "critical",
      message: `Queue failed threshold reached: failed=${failedCount}, ` +
        `threshold=${params.thresholds.failedThreshold}.`,
    });
  }

  if (
    stalenessEligibleMeasurementPointIds.size > 0 &&
    (minutesSinceGlobalWebhook === null ||
      minutesSinceGlobalWebhook >= params.thresholds.webhookStaleMinutes)
  ) {
    alerts.push({
      code: "WEBHOOK_STALE",
      severity: "warning",
      message: minutesSinceGlobalWebhook === null
        ? "No webhook timestamp found in efento_sync_state."
        : `Global webhook staleness exceeded: ${minutesSinceGlobalWebhook} min >= ${params.thresholds.webhookStaleMinutes} min.`,
    });
  }

  if (staleDataPoints.length > 0) {
    alerts.push({
      code: "DATA_STALE",
      severity: "warning",
      message:
        `Data staleness detected for ${staleDataPoints.length} measurement point(s) ` +
        `(threshold=${params.thresholds.dataStaleMinutes} min).`,
    });
  }

  if (blockedMeasurementPoints.length > 0) {
    alerts.push({
      code: "UPSTREAM_BLOCKED_POINTS",
      severity: "warning",
      message:
        `Upstream blocked measurement points detected: count=${blockedMeasurementPoints.length}. ` +
        "Blocked points are excluded from DATA_STALE/WEBHOOK_STALE checks.",
    });
  }

  const healthHourlyCount = healthResult.count ?? 0;
  if (healthHourlyCount >= params.thresholds.healthHourlyThreshold) {
    alerts.push({
      code: "HEALTH_SPIKE",
      severity: "critical",
      message:
        `Hourly health events threshold reached: count=${healthHourlyCount}, ` +
        `threshold=${params.thresholds.healthHourlyThreshold}.`,
    });
  }

  return {
    generatedAt: nowIso,
    queue: {
      pendingCount,
      processingCount,
      failedCount,
      oldestPendingAt,
      oldestPendingMinutes,
    },
    healthHourlyCount,
    measurementPoints,
    blockedMeasurementPoints: {
      count: blockedMeasurementPoints.length,
      items: blockedMeasurementPoints,
    },
    alerts,
  };
}
