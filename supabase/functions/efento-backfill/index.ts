import { createClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";
import {
  buildObservabilitySnapshot,
  loadAlertThresholdsFromEnv,
} from "../_shared/efento_observability.ts";

// Edge functions in this repo don't use generated Supabase DB types yet.
// Keep a permissive client type to avoid `never` inference in deno check.
type SupabaseServiceClient = any;

type BackfillRequest = {
  from?: string;
  to?: string;
  measurementPointId?: number;
  includeBlocked?: boolean;
  dryRun?: boolean;
  overlapMinutes?: number;
  pageSize?: number;
  maxPages?: number;
};

type UpstreamAccessState = "unknown" | "ok" | "blocked";

type MappingRow = {
  measurement_point_id: number;
  sensor_id: string;
  device_serial_number: string;
  temperature_channel_number: number;
  is_active: boolean;
  upstream_access_state: UpstreamAccessState;
};

type SyncStateRow = {
  measurement_point_id: number;
  last_webhook_received_at: string | null;
  last_successful_expand_to: string | null;
  last_successful_backfill_to: string | null;
};

type ParsedPayload = {
  measurementPointId: number;
  deviceSerialNumber: string;
  firstMeasurementTimestamp: string;
  lastMeasurementTimestamp: string;
  measurementsEvents: unknown[];
};

type ChannelEvent = {
  timestampMs: number;
  timestampIso: string;
  statusRaw: string;
  statusNormalized: string;
  periodSeconds: number | null;
  value: number | null;
};

type FrameStats = {
  temperatureCandidates: number;
  healthCandidates: number;
  temperatureInserted: number;
  healthInserted: number;
  duplicatesIgnored: number;
  expandToIso: string;
};

type FetchPageResult = {
  frames: unknown[];
  nextPageToken: string | null;
};

type FetchMappingsResult = {
  mappings: MappingRow[];
  blockedSkippedCount: number;
};

type PointOutcome = {
  measurementPointId: number;
  sensorId: string;
  upstreamAccessState: UpstreamAccessState;
  status: "done" | "partial" | "failed";
  dryRun: boolean;
  windowFrom: string;
  windowTo: string;
  pagesFetched: number;
  framesFetched: number;
  temperatureCandidates: number;
  healthCandidates: number;
  temperatureInserted: number;
  healthInserted: number;
  duplicatesIgnored: number;
  errors: string[];
};

type InsertStats = {
  inserted: number;
  duplicatesIgnored: number;
};

const JSON_HEADERS: HeadersInit = {
  "content-type": "application/json; charset=utf-8",
};

const BACKFILL_SOURCE = "efento_backfill";
const DEFAULT_THRESHOLD = 8.0;
const DEFAULT_OVERLAP_MINUTES = 15;
const DEFAULT_LOOKBACK_HOURS = 6;
const DEFAULT_PAGE_SIZE = 200;
const DEFAULT_MAX_PAGES = 20;

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
  headers: HeadersInit = JSON_HEADERS,
): Response {
  return new Response(JSON.stringify(body), { status, headers });
}

function normalizeSecret(value: string | null | undefined): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function isQuerySecretFallbackEnabled(): boolean {
  const raw = Deno.env.get("EFENTO_ALLOW_QUERY_SECRET_FALLBACK");
  if (typeof raw !== "string") {
    return false;
  }

  const normalized = raw.trim().toLowerCase();
  return normalized === "1" || normalized === "true" || normalized === "yes" ||
    normalized === "on";
}

function asObject(value: unknown): Record<string, unknown> | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function toPositiveInteger(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    return null;
  }
  return value;
}

function toNonNegativeInteger(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isInteger(value) || value < 0) {
    return null;
  }
  return value;
}

function parseTimestamp(
  value: unknown,
): { ok: true; ms: number; iso: string } | { ok: false } {
  if (typeof value !== "string" || value.trim().length === 0) {
    return { ok: false };
  }
  const date = new Date(value);
  const ms = date.getTime();
  if (Number.isNaN(ms)) {
    return { ok: false };
  }
  return { ok: true, ms, iso: date.toISOString() };
}

function normalizeStatus(value: unknown): string {
  if (typeof value !== "string") {
    return "UNKNOWN";
  }
  const normalized = value.trim().toUpperCase();
  return normalized.length > 0 ? normalized : "UNKNOWN";
}

function isOkStatus(status: string): boolean {
  return status.startsWith("OK");
}

function toHealthStatus(
  status: string,
): "MISSING" | "ERROR" | "OUT_OF_RANGE" | "UNKNOWN" {
  if (status === "MISSING" || status === "ERROR" || status === "OUT_OF_RANGE") {
    return status;
  }
  return "UNKNOWN";
}

function truncateErrorMessage(value: unknown): string {
  const fallback = "unknown_backfill_error";
  const message = value instanceof Error
    ? value.message
    : typeof value === "string"
    ? value
    : fallback;
  return message.length > 900 ? `${message.slice(0, 897)}...` : message;
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

class EfentoApiHttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.name = "EfentoApiHttpError";
    this.status = status;
  }
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

function parseBackfillRequest(rawBody: unknown): {
  ok: true;
  value: {
    dryRun: boolean;
    measurementPointId: number | null;
    includeBlocked: boolean;
    fromIso: string | null;
    toIso: string | null;
    overlapMinutes: number;
    pageSize: number;
    maxPages: number;
  };
} | { ok: false; error: string } {
  const body = asObject(rawBody) ?? {};

  let measurementPointId: number | null = null;
  if (body.measurementPointId !== undefined) {
    const parsed = toPositiveInteger(body.measurementPointId);
    if (parsed === null) {
      return {
        ok: false,
        error: "measurementPointId must be a positive integer.",
      };
    }
    measurementPointId = parsed;
  }

  let fromIso: string | null = null;
  if (body.from !== undefined) {
    const parsed = parseTimestamp(body.from);
    if (!parsed.ok) {
      return { ok: false, error: "from must be valid ISO-8601." };
    }
    fromIso = parsed.iso;
  }

  let toIso: string | null = null;
  if (body.to !== undefined) {
    const parsed = parseTimestamp(body.to);
    if (!parsed.ok) {
      return { ok: false, error: "to must be valid ISO-8601." };
    }
    toIso = parsed.iso;
  }

  if (
    fromIso && toIso && new Date(fromIso).getTime() > new Date(toIso).getTime()
  ) {
    return { ok: false, error: "from cannot be later than to." };
  }

  let includeBlocked = false;
  if (body.includeBlocked !== undefined) {
    if (typeof body.includeBlocked !== "boolean") {
      return { ok: false, error: "includeBlocked must be a boolean." };
    }
    includeBlocked = body.includeBlocked;
  }

  let overlapMinutes = DEFAULT_OVERLAP_MINUTES;
  if (body.overlapMinutes !== undefined) {
    const parsed = toNonNegativeInteger(body.overlapMinutes);
    if (parsed === null) {
      return {
        ok: false,
        error: "overlapMinutes must be a non-negative integer.",
      };
    }
    overlapMinutes = Math.min(parsed, 12 * 60);
  }

  let pageSize = DEFAULT_PAGE_SIZE;
  if (body.pageSize !== undefined) {
    const parsed = toPositiveInteger(body.pageSize);
    if (parsed === null) {
      return { ok: false, error: "pageSize must be a positive integer." };
    }
    pageSize = Math.min(parsed, 1000);
  }

  let maxPages = DEFAULT_MAX_PAGES;
  if (body.maxPages !== undefined) {
    const parsed = toPositiveInteger(body.maxPages);
    if (parsed === null) {
      return { ok: false, error: "maxPages must be a positive integer." };
    }
    maxPages = Math.min(parsed, 500);
  }

  return {
    ok: true,
    value: {
      dryRun: body.dryRun === true,
      measurementPointId,
      includeBlocked,
      fromIso,
      toIso,
      overlapMinutes,
      pageSize,
      maxPages,
    },
  };
}

function buildTemperatureSourceRef(
  measurementPointId: number,
  channelNumber: number,
  timestampIso: string,
): string {
  return `mp:${measurementPointId}|ch:${channelNumber}|ts:${timestampIso}`;
}

function buildHealthSourceRef(
  measurementPointId: number,
  channelNumber: number,
  timestampIso: string,
  status: string,
): string {
  return `mp:${measurementPointId}|ch:${channelNumber}|ts:${timestampIso}|status:${status}`;
}

function dedupeBySourceRef<T extends { source_ref: string }>(rows: T[]): T[] {
  const map = new Map<string, T>();
  for (const row of rows) {
    map.set(row.source_ref, row);
  }
  return Array.from(map.values());
}

function deriveWindowFromEvents(
  measurementsEvents: unknown[],
): { firstIso: string; lastIso: string } | null {
  let firstMs: number | null = null;
  let lastMs: number | null = null;

  for (const channelRaw of measurementsEvents) {
    const channel = asObject(channelRaw);
    if (!channel) {
      continue;
    }
    const events = Array.isArray(channel.events) ? channel.events : [];
    for (const eventRaw of events) {
      const event = asObject(eventRaw);
      if (!event) {
        continue;
      }
      const timestamp = parseTimestamp(event.timestamp);
      if (!timestamp.ok) {
        continue;
      }
      if (firstMs === null || timestamp.ms < firstMs) {
        firstMs = timestamp.ms;
      }
      if (lastMs === null || timestamp.ms > lastMs) {
        lastMs = timestamp.ms;
      }
    }
  }

  if (firstMs === null || lastMs === null) {
    return null;
  }

  return {
    firstIso: new Date(firstMs).toISOString(),
    lastIso: new Date(lastMs).toISOString(),
  };
}

function parsePayload(
  payload: unknown,
  fallbackPointId: number,
  fallbackSerial: string,
): {
  ok: true;
  value: ParsedPayload;
} | { ok: false; error: string } {
  const objectPayload = asObject(payload);
  if (!objectPayload) {
    return { ok: false, error: "frame is not a JSON object" };
  }

  const measurementPointId =
    toPositiveInteger(objectPayload.measurementPointId) ?? fallbackPointId;
  if (measurementPointId <= 0) {
    return { ok: false, error: "measurementPointId must be positive" };
  }

  const deviceSerialNumber =
    typeof objectPayload.deviceSerialNumber === "string"
      ? objectPayload.deviceSerialNumber.trim()
      : fallbackSerial.trim();
  if (deviceSerialNumber.length === 0) {
    return { ok: false, error: "deviceSerialNumber is empty" };
  }

  const measurementsEvents = objectPayload.measurementsEvents;
  if (!Array.isArray(measurementsEvents) || measurementsEvents.length === 0) {
    return { ok: false, error: "measurementsEvents must be non-empty array" };
  }

  const parsedFirst = parseTimestamp(objectPayload.firstMeasurementTimestamp);
  const parsedLast = parseTimestamp(objectPayload.lastMeasurementTimestamp);
  const derivedWindow = deriveWindowFromEvents(measurementsEvents);

  const firstMeasurementTimestamp = parsedFirst.ok
    ? parsedFirst.iso
    : derivedWindow?.firstIso ?? null;
  const lastMeasurementTimestamp = parsedLast.ok
    ? parsedLast.iso
    : derivedWindow?.lastIso ?? null;

  if (!firstMeasurementTimestamp || !lastMeasurementTimestamp) {
    return { ok: false, error: "frame has invalid first/last timestamps" };
  }

  if (
    new Date(firstMeasurementTimestamp).getTime() >
      new Date(lastMeasurementTimestamp).getTime()
  ) {
    return {
      ok: false,
      error: "firstMeasurementTimestamp later than lastMeasurementTimestamp",
    };
  }

  return {
    ok: true,
    value: {
      measurementPointId,
      deviceSerialNumber,
      firstMeasurementTimestamp,
      lastMeasurementTimestamp,
      measurementsEvents,
    },
  };
}

function selectTemperatureChannel(
  channels: unknown[],
  expectedChannelNumber: number,
): { channelNumber: number; events: unknown[] } | null {
  const parsedChannels = channels
    .map((item) => asObject(item))
    .filter((item): item is Record<string, unknown> => item !== null)
    .map((item) => {
      const channelNumber = toPositiveInteger(item.channelNumber);
      const channelType = typeof item.channelType === "string"
        ? item.channelType.trim().toUpperCase()
        : "";
      const events = Array.isArray(item.events) ? item.events : [];
      return { channelNumber, channelType, events };
    })
    .filter((item) =>
      item.channelNumber !== null && item.channelType === "TEMPERATURE" &&
      item.events.length > 0
    )
    .map((item) => ({
      channelNumber: item.channelNumber as number,
      events: item.events,
    }));

  const exact = parsedChannels.find((item) =>
    item.channelNumber === expectedChannelNumber
  );
  if (exact) {
    return exact;
  }
  return parsedChannels.length > 0 ? parsedChannels[0] : null;
}

function parseChannelEvents(rawEvents: unknown[]): ChannelEvent[] {
  const parsed = rawEvents
    .map((item) => asObject(item))
    .filter((item): item is Record<string, unknown> => item !== null)
    .map((item) => {
      const timestamp = parseTimestamp(item.timestamp);
      if (!timestamp.ok) {
        return null;
      }
      const statusNormalized = normalizeStatus(item.status);
      const periodSeconds = toPositiveInteger(item.period);
      const value =
        typeof item.value === "number" && Number.isFinite(item.value)
          ? item.value
          : null;
      return {
        timestampMs: timestamp.ms,
        timestampIso: timestamp.iso,
        statusRaw: typeof item.status === "string" ? item.status : "UNKNOWN",
        statusNormalized,
        periodSeconds,
        value,
      } satisfies ChannelEvent;
    })
    .filter((item): item is ChannelEvent => item !== null);

  parsed.sort((a, b) => a.timestampMs - b.timestampMs);
  return parsed;
}

function expandTemperatureSeries(params: {
  measurementPointId: number;
  channelNumber: number;
  firstTimestampIso: string;
  lastTimestampIso: string;
  events: ChannelEvent[];
}): {
  temperatureCandidates: Array<{ timestampIso: string; value: number }>;
  healthCandidates: Array<
    {
      timestampIso: string;
      status: "MISSING" | "ERROR" | "OUT_OF_RANGE" | "UNKNOWN";
      rawValue: string | null;
      sourceRef: string;
      details: Record<string, unknown>;
    }
  >;
} {
  const firstParsed = parseTimestamp(params.firstTimestampIso);
  const lastParsed = parseTimestamp(params.lastTimestampIso);
  if (!firstParsed.ok || !lastParsed.ok) {
    return { temperatureCandidates: [], healthCandidates: [] };
  }

  const windowStartMs = firstParsed.ms;
  const windowEndMs = lastParsed.ms;
  const temperatureCandidates: Array<{ timestampIso: string; value: number }> =
    [];
  const healthCandidates: Array<
    {
      timestampIso: string;
      status: "MISSING" | "ERROR" | "OUT_OF_RANGE" | "UNKNOWN";
      rawValue: string | null;
      sourceRef: string;
      details: Record<string, unknown>;
    }
  > = [];

  for (let i = 0; i < params.events.length; i += 1) {
    const event = params.events[i];
    const nextEvent = params.events[i + 1];

    if (event.timestampMs > windowEndMs) {
      continue;
    }

    if (isOkStatus(event.statusNormalized)) {
      if (event.value === null || event.periodSeconds === null) {
        if (
          event.timestampMs >= windowStartMs && event.timestampMs <= windowEndMs
        ) {
          healthCandidates.push({
            timestampIso: event.timestampIso,
            status: "UNKNOWN",
            rawValue: event.value === null ? null : String(event.value),
            sourceRef: buildHealthSourceRef(
              params.measurementPointId,
              params.channelNumber,
              event.timestampIso,
              "UNKNOWN",
            ),
            details: {
              reason: "invalid_ok_event",
              status: event.statusRaw,
              period: event.periodSeconds,
            },
          });
        }
        continue;
      }

      const periodMs = event.periodSeconds * 1000;
      const segmentEndExclusive = nextEvent
        ? Math.min(nextEvent.timestampMs, windowEndMs + 1)
        : windowEndMs + 1;
      let firstSampleMs = event.timestampMs;
      if (firstSampleMs < windowStartMs) {
        const missingWindowMs = windowStartMs - firstSampleMs;
        const steps = Math.ceil(missingWindowMs / periodMs);
        firstSampleMs += steps * periodMs;
      }

      for (
        let cursorMs = firstSampleMs;
        cursorMs < segmentEndExclusive;
        cursorMs += periodMs
      ) {
        if (cursorMs < windowStartMs || cursorMs > windowEndMs) {
          continue;
        }
        temperatureCandidates.push({
          timestampIso: new Date(cursorMs).toISOString(),
          value: event.value,
        });
      }
      continue;
    }

    if (
      event.timestampMs >= windowStartMs && event.timestampMs <= windowEndMs
    ) {
      const status = toHealthStatus(event.statusNormalized);
      healthCandidates.push({
        timestampIso: event.timestampIso,
        status,
        rawValue: event.value === null ? null : String(event.value),
        sourceRef: buildHealthSourceRef(
          params.measurementPointId,
          params.channelNumber,
          event.timestampIso,
          status,
        ),
        details: {
          status_raw: event.statusRaw,
          period_seconds: event.periodSeconds,
        },
      });
    }
  }

  return { temperatureCandidates, healthCandidates };
}

function isUniqueViolation(
  error: { code?: string; message?: string } | null | undefined,
): boolean {
  if (!error) {
    return false;
  }
  if (error.code === "23505") {
    return true;
  }
  const message = typeof error.message === "string"
    ? error.message.toLowerCase()
    : "";
  return message.includes("duplicate key value") ||
    message.includes("unique constraint");
}

async function insertRowsIgnoringDuplicates(
  supabase: SupabaseServiceClient,
  tableName: "temperature_logs" | "efento_health_events",
  rows: Record<string, unknown>[],
): Promise<InsertStats> {
  let inserted = 0;
  let duplicatesIgnored = 0;
  for (const row of rows) {
    const result = await supabase.from(tableName).insert(row);
    if (result.error) {
      if (isUniqueViolation(result.error)) {
        duplicatesIgnored += 1;
        continue;
      }
      throw new Error(`${tableName} insert failed: ${result.error.message}`);
    }
    inserted += 1;
  }
  return { inserted, duplicatesIgnored };
}

async function fetchSensorThreshold(
  supabase: SupabaseServiceClient,
  sensorId: string,
  cache: Map<string, number>,
): Promise<number> {
  const cached = cache.get(sensorId);
  if (typeof cached === "number") {
    return cached;
  }

  const sensorResult = await supabase.from("sensors").select("id,zone_id").eq(
    "id",
    sensorId,
  ).maybeSingle();
  if (sensorResult.error) {
    throw new Error(`sensor lookup failed: ${sensorResult.error.message}`);
  }
  if (!sensorResult.data?.zone_id) {
    throw new Error(`sensor ${sensorId} has no zone_id`);
  }

  const zoneResult = await supabase.from("zones").select("id,venue_id").eq(
    "id",
    sensorResult.data.zone_id,
  ).maybeSingle();
  if (zoneResult.error) {
    throw new Error(`zone lookup failed: ${zoneResult.error.message}`);
  }
  if (!zoneResult.data?.venue_id) {
    throw new Error(`zone ${sensorResult.data.zone_id} has no venue_id`);
  }

  const venueResult = await supabase.from("venues").select("id,temp_threshold")
    .eq("id", zoneResult.data.venue_id).maybeSingle();
  if (venueResult.error) {
    throw new Error(`venue lookup failed: ${venueResult.error.message}`);
  }

  const threshold = typeof venueResult.data?.temp_threshold === "number" &&
      Number.isFinite(venueResult.data.temp_threshold)
    ? venueResult.data.temp_threshold
    : DEFAULT_THRESHOLD;

  cache.set(sensorId, threshold);
  return threshold;
}

async function fetchMappings(
  supabase: SupabaseServiceClient,
  measurementPointId: number | null,
  includeBlocked: boolean,
): Promise<FetchMappingsResult> {
  let hasUpstreamAccessStateColumn = true;
  let blockedSkippedCount = 0;

  if (!includeBlocked) {
    let blockedCountQuery = supabase
      .from("efento_measurement_point_map")
      .select("measurement_point_id", { head: true, count: "exact" })
      .eq("is_active", true)
      .eq("upstream_access_state", "blocked");

    if (measurementPointId !== null) {
      blockedCountQuery = blockedCountQuery.eq(
        "measurement_point_id",
        measurementPointId,
      );
    }

    const blockedCountResult = await blockedCountQuery;
    if (blockedCountResult.error) {
      if (isMissingUpstreamAccessStateColumnError(blockedCountResult.error)) {
        hasUpstreamAccessStateColumn = false;
      } else {
        throw new Error(
          `mapping blocked-count lookup failed: ${blockedCountResult.error.message}`,
        );
      }
    } else {
      blockedSkippedCount = blockedCountResult.count ?? 0;
    }
  }

  const buildMappingsQuery = (withUpstreamColumn: boolean) => {
    let query = supabase
      .from("efento_measurement_point_map")
      .select(
        withUpstreamColumn
          ? "measurement_point_id,sensor_id,device_serial_number,temperature_channel_number,is_active,upstream_access_state"
          : "measurement_point_id,sensor_id,device_serial_number,temperature_channel_number,is_active",
      )
      .eq("is_active", true)
      .order("measurement_point_id", { ascending: true });

    if (measurementPointId !== null) {
      query = query.eq("measurement_point_id", measurementPointId);
    }
    if (!includeBlocked && withUpstreamColumn) {
      query = query.neq("upstream_access_state", "blocked");
    }
    return query;
  };

  const firstResult = await buildMappingsQuery(hasUpstreamAccessStateColumn);
  if (
    firstResult.error && hasUpstreamAccessStateColumn &&
    isMissingUpstreamAccessStateColumnError(firstResult.error)
  ) {
    hasUpstreamAccessStateColumn = false;
  } else if (firstResult.error) {
    throw new Error(`mapping lookup failed: ${firstResult.error.message}`);
  }

  const result = hasUpstreamAccessStateColumn
    ? firstResult
    : await buildMappingsQuery(false);
  if (result.error) {
    throw new Error(`mapping lookup failed: ${result.error.message}`);
  }

  const mappings = ((result.data ?? []) as Array<Record<string, unknown>>).map(
    (row) => ({
      measurement_point_id: Number(row.measurement_point_id),
      sensor_id: String(row.sensor_id),
      device_serial_number: String(row.device_serial_number),
      temperature_channel_number: Number(row.temperature_channel_number),
      is_active: row.is_active === true,
      upstream_access_state: hasUpstreamAccessStateColumn &&
          (row.upstream_access_state === "blocked" ||
            row.upstream_access_state === "ok")
        ? row.upstream_access_state
        : "unknown",
    } as MappingRow),
  );

  return {
    mappings,
    blockedSkippedCount,
  };
}

async function updateMappingUpstreamAccessState(params: {
  supabase: SupabaseServiceClient;
  measurementPointId: number;
  state: UpstreamAccessState;
  lastError: string | null;
}): Promise<void> {
  const result = await params.supabase
    .from("efento_measurement_point_map")
    .update({
      upstream_access_state: params.state,
      upstream_access_last_checked_at: new Date().toISOString(),
      upstream_access_last_error: params.lastError,
      updated_at: new Date().toISOString(),
    })
    .eq("measurement_point_id", params.measurementPointId);

  if (result.error) {
    if (isMissingUpstreamAccessStateColumnError(result.error)) {
      return;
    }
    throw new Error(
      `mapping upstream_access_state update failed: ${result.error.message}`,
    );
  }
}

async function fetchSyncStateMap(
  supabase: SupabaseServiceClient,
  measurementPointIds: number[],
): Promise<Map<number, SyncStateRow>> {
  const map = new Map<number, SyncStateRow>();
  if (measurementPointIds.length === 0) {
    return map;
  }

  const result = await supabase
    .from("efento_sync_state")
    .select(
      "measurement_point_id,last_webhook_received_at,last_successful_expand_to,last_successful_backfill_to",
    )
    .in("measurement_point_id", measurementPointIds);

  if (result.error) {
    throw new Error(`sync_state lookup failed: ${result.error.message}`);
  }

  for (const row of (result.data ?? []) as SyncStateRow[]) {
    map.set(row.measurement_point_id, row);
  }
  return map;
}

function resolveWindow(params: {
  nowIso: string;
  syncState: SyncStateRow | undefined;
  requestedFromIso: string | null;
  requestedToIso: string | null;
  overlapMinutes: number;
  defaultLookbackHours: number;
}): { fromIso: string; toIso: string } {
  const nowParsed = parseTimestamp(params.nowIso);
  const nowMs = nowParsed.ok ? nowParsed.ms : Date.now();
  const toParsed = parseTimestamp(params.requestedToIso);
  const toMs = toParsed.ok ? toParsed.ms : nowMs;

  const requestedFrom = parseTimestamp(params.requestedFromIso);
  let fromMs: number;

  if (requestedFrom.ok) {
    fromMs = requestedFrom.ms;
  } else {
    const candidates = [
      params.syncState?.last_successful_backfill_to ?? null,
      params.syncState?.last_successful_expand_to ?? null,
      params.syncState?.last_webhook_received_at ?? null,
    ];
    let maxCandidateMs: number | null = null;
    for (const candidate of candidates) {
      const parsed = parseTimestamp(candidate);
      if (!parsed.ok) {
        continue;
      }
      if (maxCandidateMs === null || parsed.ms > maxCandidateMs) {
        maxCandidateMs = parsed.ms;
      }
    }
    fromMs = maxCandidateMs ??
      (toMs - params.defaultLookbackHours * 3600 * 1000);
  }

  fromMs -= params.overlapMinutes * 60 * 1000;
  if (fromMs > toMs) {
    fromMs = toMs - 60 * 1000;
  }

  return {
    fromIso: new Date(fromMs).toISOString(),
    toIso: new Date(toMs).toISOString(),
  };
}

function extractNextPageToken(payload: Record<string, unknown>): string | null {
  const direct = payload.nextPageToken ?? payload.next_page_token ??
    payload.pageToken ?? payload.next;
  if (typeof direct === "string" && direct.trim().length > 0) {
    return direct.trim();
  }

  const pagination = asObject(payload.pagination);
  if (!pagination) {
    return null;
  }

  const nested = pagination.nextPageToken ?? pagination.next_page_token ??
    pagination.pageToken ?? pagination.next;
  if (typeof nested === "string" && nested.trim().length > 0) {
    return nested.trim();
  }
  return null;
}

function extractFramesFromApiResponse(payload: unknown): FetchPageResult {
  if (Array.isArray(payload)) {
    return { frames: payload, nextPageToken: null };
  }

  const objectPayload = asObject(payload);
  if (!objectPayload) {
    throw new Error("Efento API response must be a JSON object or array");
  }

  if (Array.isArray(objectPayload.items)) {
    return {
      frames: objectPayload.items,
      nextPageToken: extractNextPageToken(objectPayload),
    };
  }
  if (Array.isArray(objectPayload.data)) {
    return {
      frames: objectPayload.data,
      nextPageToken: extractNextPageToken(objectPayload),
    };
  }
  if (Array.isArray(objectPayload.measurements)) {
    return {
      frames: objectPayload.measurements,
      nextPageToken: extractNextPageToken(objectPayload),
    };
  }

  const nestedData = asObject(objectPayload.data);
  if (nestedData && Array.isArray(nestedData.items)) {
    return {
      frames: nestedData.items,
      nextPageToken: extractNextPageToken(objectPayload) ??
        extractNextPageToken(nestedData),
    };
  }

  throw new Error(
    "Efento API response does not include items/data/measurements array",
  );
}

async function fetchBackfillPage(params: {
  apiUrl: string;
  apiToken: string;
  measurementPointId: number;
  fromIso: string;
  toIso: string;
  pageSize: number;
  pageToken: string | null;
}): Promise<FetchPageResult> {
  const url = new URL(params.apiUrl);
  url.searchParams.set("measurementPointId", String(params.measurementPointId));
  url.searchParams.set("from", params.fromIso);
  url.searchParams.set("to", params.toIso);
  url.searchParams.set("pageSize", String(params.pageSize));
  if (params.pageToken) {
    url.searchParams.set("pageToken", params.pageToken);
  }

  const response = await fetch(url, {
    method: "GET",
    headers: {
      accept: "application/json",
      authorization: `Bearer ${params.apiToken}`,
      "x-efento-api-token": params.apiToken,
    },
    signal: AbortSignal.timeout(20000),
  });

  if (!response.ok) {
    const responseText = await response.text();
    const shortened = responseText.length > 300
      ? `${responseText.slice(0, 297)}...`
      : responseText;
    throw new EfentoApiHttpError(
      response.status,
      `Efento API request failed (${response.status}): ${shortened}`,
    );
  }

  let payload: unknown;
  try {
    payload = await response.json();
  } catch {
    throw new Error("Efento API response is not valid JSON");
  }

  return extractFramesFromApiResponse(payload);
}

async function upsertBackfillSyncState(params: {
  supabase: SupabaseServiceClient;
  measurementPointId: number;
  status: "ok" | "partial" | "failed" | "dry_run";
  successfulToIso: string | null;
}): Promise<void> {
  const existing = await params.supabase
    .from("efento_sync_state")
    .select("measurement_point_id,last_successful_backfill_to")
    .eq("measurement_point_id", params.measurementPointId)
    .maybeSingle();

  if (existing.error) {
    throw new Error(`sync_state lookup failed: ${existing.error.message}`);
  }

  const existingTo = parseTimestamp(existing.data?.last_successful_backfill_to);
  const incomingTo = parseTimestamp(params.successfulToIso);

  let targetTo: string | null = null;
  if (existingTo.ok && incomingTo.ok) {
    targetTo = existingTo.ms >= incomingTo.ms ? existingTo.iso : incomingTo.iso;
  } else if (incomingTo.ok) {
    targetTo = incomingTo.iso;
  } else if (existingTo.ok) {
    targetTo = existingTo.iso;
  }

  const payload: Record<string, unknown> = {
    measurement_point_id: params.measurementPointId,
    last_backfill_status: params.status,
    updated_at: new Date().toISOString(),
  };

  if (targetTo && params.status !== "dry_run") {
    payload.last_successful_backfill_to = targetTo;
  }

  const result = await params.supabase.from("efento_sync_state").upsert(
    payload,
    {
      onConflict: "measurement_point_id",
    },
  );
  if (result.error) {
    throw new Error(`sync_state upsert failed: ${result.error.message}`);
  }
}

function maxIsoTimestamp(
  currentIso: string | null,
  candidateIso: string,
): string {
  const current = parseTimestamp(currentIso);
  const candidate = parseTimestamp(candidateIso);
  if (!candidate.ok) {
    return currentIso ?? new Date().toISOString();
  }
  if (!current.ok) {
    return candidate.iso;
  }
  return current.ms >= candidate.ms ? current.iso : candidate.iso;
}

async function processFrame(params: {
  supabase: SupabaseServiceClient;
  frame: unknown;
  mapping: MappingRow;
  sensorThreshold: number;
  dryRun: boolean;
}): Promise<FrameStats> {
  const parsedPayload = parsePayload(
    params.frame,
    params.mapping.measurement_point_id,
    params.mapping.device_serial_number,
  );
  if (!parsedPayload.ok) {
    throw new Error(parsedPayload.error);
  }

  if (
    parsedPayload.value.measurementPointId !==
      params.mapping.measurement_point_id
  ) {
    throw new Error(
      `frame measurementPointId=${parsedPayload.value.measurementPointId} does not match mapping=${params.mapping.measurement_point_id}`,
    );
  }

  const channel = selectTemperatureChannel(
    parsedPayload.value.measurementsEvents,
    params.mapping.temperature_channel_number,
  );
  if (!channel) {
    throw new Error("temperature channel not found");
  }

  const channelEvents = parseChannelEvents(channel.events);
  if (channelEvents.length === 0) {
    throw new Error("temperature channel has no valid events");
  }

  const expansion = expandTemperatureSeries({
    measurementPointId: parsedPayload.value.measurementPointId,
    channelNumber: channel.channelNumber,
    firstTimestampIso: parsedPayload.value.firstMeasurementTimestamp,
    lastTimestampIso: parsedPayload.value.lastMeasurementTimestamp,
    events: channelEvents,
  });

  const temperatureRows = dedupeBySourceRef(
    expansion.temperatureCandidates.map((item) => ({
      sensor_id: params.mapping.sensor_id,
      temperature_celsius: Math.round(item.value * 100) / 100,
      recorded_at: item.timestampIso,
      is_alert: item.value > params.sensorThreshold,
      is_acknowledged: false,
      source: BACKFILL_SOURCE,
      source_ref: buildTemperatureSourceRef(
        parsedPayload.value.measurementPointId,
        channel.channelNumber,
        item.timestampIso,
      ),
    })),
  );

  const healthRows = dedupeBySourceRef(
    expansion.healthCandidates.map((item) => ({
      measurement_point_id: parsedPayload.value.measurementPointId,
      sensor_id: params.mapping.sensor_id,
      device_serial_number: parsedPayload.value.deviceSerialNumber,
      channel_number: channel.channelNumber,
      channel_type: "TEMPERATURE",
      event_timestamp: item.timestampIso,
      status: item.status,
      raw_value: item.rawValue,
      details: item.details,
      source: BACKFILL_SOURCE,
      source_ref: item.sourceRef,
    })),
  );

  if (params.dryRun) {
    return {
      temperatureCandidates: temperatureRows.length,
      healthCandidates: healthRows.length,
      temperatureInserted: 0,
      healthInserted: 0,
      duplicatesIgnored: 0,
      expandToIso: parsedPayload.value.lastMeasurementTimestamp,
    };
  }

  let temperatureInserted = 0;
  let healthInserted = 0;
  let duplicatesIgnored = 0;

  if (temperatureRows.length > 0) {
    const result = await insertRowsIgnoringDuplicates(
      params.supabase,
      "temperature_logs",
      temperatureRows,
    );
    temperatureInserted += result.inserted;
    duplicatesIgnored += result.duplicatesIgnored;
  }

  if (healthRows.length > 0) {
    const result = await insertRowsIgnoringDuplicates(
      params.supabase,
      "efento_health_events",
      healthRows,
    );
    healthInserted += result.inserted;
    duplicatesIgnored += result.duplicatesIgnored;
  }

  return {
    temperatureCandidates: temperatureRows.length,
    healthCandidates: healthRows.length,
    temperatureInserted,
    healthInserted,
    duplicatesIgnored,
    expandToIso: parsedPayload.value.lastMeasurementTimestamp,
  };
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(
      405,
      {
        error: "method_not_allowed",
        message: "Only POST is supported.",
      },
      {
        ...JSON_HEADERS,
        allow: "POST",
      },
    );
  }

  const backfillSecret = normalizeSecret(
    Deno.env.get("EFENTO_BACKFILL_SECRET"),
  );
  if (!backfillSecret) {
    console.error("efento-backfill: missing EFENTO_BACKFILL_SECRET");
    return jsonResponse(500, {
      error: "server_misconfigured",
      message: "Backfill secret is not configured.",
    });
  }

  const requestUrl = new URL(request.url);
  const headerSecret = normalizeSecret(
    request.headers.get("x-haccp-backfill-secret"),
  );
  const querySecret = normalizeSecret(requestUrl.searchParams.get("secret"));
  const queryFallbackEnabled = isQuerySecretFallbackEnabled();

  const providedSecret = headerSecret ??
    (queryFallbackEnabled ? querySecret : null);

  if (!headerSecret && querySecret && !queryFallbackEnabled) {
    return jsonResponse(401, {
      error: "unauthorized",
      message:
        "Query-string secret is disabled. Use X-HACCP-Backfill-Secret header.",
    });
  }

  if (!providedSecret) {
    return jsonResponse(401, {
      error: "unauthorized",
      message: "Backfill secret is required.",
    });
  }
  if (providedSecret !== backfillSecret) {
    return jsonResponse(403, {
      error: "forbidden",
      message: "Invalid backfill secret.",
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("efento-backfill: missing Supabase runtime env vars");
    return jsonResponse(500, {
      error: "server_misconfigured",
      message: "Supabase server credentials are missing.",
    });
  }

  const efentoApiUrl = Deno.env.get("EFENTO_API_MEASUREMENTS_URL");
  const efentoApiToken = Deno.env.get("EFENTO_API_TOKEN");
  if (!efentoApiUrl || !efentoApiToken) {
    console.error("efento-backfill: missing Efento API env vars");
    return jsonResponse(500, {
      error: "server_misconfigured",
      message: "Efento API URL/token are missing.",
    });
  }

  let body: BackfillRequest | null = null;
  try {
    body = request.headers.get("content-length") === "0"
      ? {}
      : await request.json();
  } catch {
    return jsonResponse(400, {
      error: "invalid_json",
      message: "Request body must be valid JSON.",
    });
  }

  const parsedRequest = parseBackfillRequest(body);
  if (!parsedRequest.ok) {
    return jsonResponse(400, {
      error: "invalid_request",
      message: parsedRequest.error,
    });
  }

  const defaultLookbackHours = parseEnvInt(
    Deno.env.get("EFENTO_BACKFILL_DEFAULT_LOOKBACK_HOURS"),
    DEFAULT_LOOKBACK_HOURS,
    1,
    168,
  );

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  let mappings: MappingRow[];
  let blockedSkippedCount = 0;
  try {
    const mappingsResult = await fetchMappings(
      supabase,
      parsedRequest.value.measurementPointId,
      parsedRequest.value.includeBlocked,
    );
    mappings = mappingsResult.mappings;
    blockedSkippedCount = mappingsResult.blockedSkippedCount;
  } catch (error) {
    return jsonResponse(500, {
      error: "mapping_lookup_failed",
      message: truncateErrorMessage(error),
    });
  }

  if (mappings.length === 0) {
    return jsonResponse(404, {
      error: "no_active_mapping",
      message: parsedRequest.value.measurementPointId === null
        ? "No active measurement point mappings found."
        : `No active mapping for measurementPointId=${parsedRequest.value.measurementPointId}.`,
      blockedSkippedCount,
      includeBlocked: parsedRequest.value.includeBlocked,
    });
  }

  let syncStateMap: Map<number, SyncStateRow>;
  try {
    syncStateMap = await fetchSyncStateMap(
      supabase,
      mappings.map((item) => item.measurement_point_id),
    );
  } catch (error) {
    return jsonResponse(500, {
      error: "sync_state_lookup_failed",
      message: truncateErrorMessage(error),
    });
  }

  const sensorThresholdCache = new Map<string, number>();
  const outcomes: PointOutcome[] = [];

  let totalPagesFetched = 0;
  let totalFramesFetched = 0;
  let totalTemperatureCandidates = 0;
  let totalHealthCandidates = 0;
  let totalTemperatureInserted = 0;
  let totalHealthInserted = 0;
  let totalDuplicatesIgnored = 0;
  let totalErrors = 0;
  let totalUpstream403Count = 0;

  for (const mapping of mappings) {
    const window = resolveWindow({
      nowIso: new Date().toISOString(),
      syncState: syncStateMap.get(mapping.measurement_point_id),
      requestedFromIso: parsedRequest.value.fromIso,
      requestedToIso: parsedRequest.value.toIso,
      overlapMinutes: parsedRequest.value.overlapMinutes,
      defaultLookbackHours,
    });

    const outcome: PointOutcome = {
      measurementPointId: mapping.measurement_point_id,
      sensorId: mapping.sensor_id,
      upstreamAccessState: mapping.upstream_access_state,
      status: "done",
      dryRun: parsedRequest.value.dryRun,
      windowFrom: window.fromIso,
      windowTo: window.toIso,
      pagesFetched: 0,
      framesFetched: 0,
      temperatureCandidates: 0,
      healthCandidates: 0,
      temperatureInserted: 0,
      healthInserted: 0,
      duplicatesIgnored: 0,
      errors: [],
    };

    let latestSuccessfulFrameIso: string | null = null;
    let pageToken: string | null = null;
    let sensorThreshold = DEFAULT_THRESHOLD;
    let upstreamRequestSucceeded = false;
    let blockedStateUpdated = false;

    try {
      sensorThreshold = await fetchSensorThreshold(
        supabase,
        mapping.sensor_id,
        sensorThresholdCache,
      );
    } catch (error) {
      outcome.status = "failed";
      outcome.errors.push(truncateErrorMessage(error));
    }

    if (outcome.status !== "failed") {
      for (let page = 0; page < parsedRequest.value.maxPages; page += 1) {
        let pageResult: FetchPageResult;
        try {
          pageResult = await fetchBackfillPage({
            apiUrl: efentoApiUrl,
            apiToken: efentoApiToken,
            measurementPointId: mapping.measurement_point_id,
            fromIso: window.fromIso,
            toIso: window.toIso,
            pageSize: parsedRequest.value.pageSize,
            pageToken,
          });
          upstreamRequestSucceeded = true;
        } catch (error) {
          const errorMessage = truncateErrorMessage(error);
          outcome.errors.push(errorMessage);
          if (
            !parsedRequest.value.dryRun &&
            error instanceof EfentoApiHttpError && error.status === 403
          ) {
            totalUpstream403Count += 1;
            try {
              await updateMappingUpstreamAccessState({
                supabase,
                measurementPointId: mapping.measurement_point_id,
                state: "blocked",
                lastError: errorMessage,
              });
              outcome.upstreamAccessState = "blocked";
              blockedStateUpdated = true;
            } catch (updateError) {
              outcome.errors.push(
                `mapping_state_update_failed: ${
                  truncateErrorMessage(updateError)
                }`,
              );
            }
          }
          break;
        }

        outcome.pagesFetched += 1;
        totalPagesFetched += 1;

        for (const frame of pageResult.frames) {
          outcome.framesFetched += 1;
          totalFramesFetched += 1;
          try {
            const frameStats = await processFrame({
              supabase,
              frame,
              mapping,
              sensorThreshold,
              dryRun: parsedRequest.value.dryRun,
            });

            outcome.temperatureCandidates += frameStats.temperatureCandidates;
            outcome.healthCandidates += frameStats.healthCandidates;
            outcome.temperatureInserted += frameStats.temperatureInserted;
            outcome.healthInserted += frameStats.healthInserted;
            outcome.duplicatesIgnored += frameStats.duplicatesIgnored;

            totalTemperatureCandidates += frameStats.temperatureCandidates;
            totalHealthCandidates += frameStats.healthCandidates;
            totalTemperatureInserted += frameStats.temperatureInserted;
            totalHealthInserted += frameStats.healthInserted;
            totalDuplicatesIgnored += frameStats.duplicatesIgnored;

            latestSuccessfulFrameIso = maxIsoTimestamp(
              latestSuccessfulFrameIso,
              frameStats.expandToIso,
            );
          } catch (error) {
            outcome.errors.push(truncateErrorMessage(error));
          }
        }

        if (!pageResult.nextPageToken) {
          break;
        }
        pageToken = pageResult.nextPageToken;
      }
    }

    if (
      !parsedRequest.value.dryRun && upstreamRequestSucceeded &&
      !blockedStateUpdated
    ) {
      try {
        await updateMappingUpstreamAccessState({
          supabase,
          measurementPointId: mapping.measurement_point_id,
          state: "ok",
          lastError: null,
        });
        outcome.upstreamAccessState = "ok";
      } catch (updateError) {
        outcome.errors.push(
          `mapping_state_update_failed: ${truncateErrorMessage(updateError)}`,
        );
      }
    }

    if (outcome.errors.length > 0) {
      totalErrors += outcome.errors.length;
      if (
        outcome.temperatureCandidates > 0 || outcome.healthCandidates > 0 ||
        outcome.temperatureInserted > 0
      ) {
        outcome.status = "partial";
      } else {
        outcome.status = "failed";
      }
    }

    const syncStatus: "ok" | "partial" | "failed" | "dry_run" =
      parsedRequest.value.dryRun
        ? (outcome.status === "failed" ? "failed" : "dry_run")
        : outcome.status === "done"
        ? "ok"
        : outcome.status === "partial"
        ? "partial"
        : "failed";

    try {
      await upsertBackfillSyncState({
        supabase,
        measurementPointId: mapping.measurement_point_id,
        status: syncStatus,
        successfulToIso: latestSuccessfulFrameIso,
      });
    } catch (error) {
      outcome.status = "failed";
      outcome.errors.push(
        `sync_state_update_failed: ${truncateErrorMessage(error)}`,
      );
      totalErrors += 1;
    }

    if (outcome.errors.length > 5) {
      outcome.errors = outcome.errors.slice(0, 5);
    }

    outcomes.push(outcome);
  }

  const doneCount = outcomes.filter((item) => item.status === "done").length;
  const partialCount = outcomes.filter((item) =>
    item.status === "partial"
  ).length;
  const failedCount =
    outcomes.filter((item) => item.status === "failed").length;

  let observability: unknown = null;
  try {
    observability = await buildObservabilitySnapshot({
      supabase,
      thresholds: loadAlertThresholdsFromEnv(),
    });
  } catch (error) {
    console.error("efento-backfill: observability snapshot failed", {
      error: truncateErrorMessage(error),
    });
  }

  console.log("efento-backfill: run completed", {
    dryRun: parsedRequest.value.dryRun,
    includeBlocked: parsedRequest.value.includeBlocked,
    mappingsRequested: mappings.length,
    blockedSkippedCount,
    doneCount,
    partialCount,
    failedCount,
    totalPagesFetched,
    totalFramesFetched,
    totalTemperatureCandidates,
    totalHealthCandidates,
    totalTemperatureInserted,
    totalHealthInserted,
    totalDuplicatesIgnored,
    totalUpstream403Count,
    totalErrors,
  });

  return jsonResponse(200, {
    ok: failedCount === 0,
    dryRun: parsedRequest.value.dryRun,
    request: {
      measurementPointId: parsedRequest.value.measurementPointId,
      includeBlocked: parsedRequest.value.includeBlocked,
      from: parsedRequest.value.fromIso,
      to: parsedRequest.value.toIso,
      overlapMinutes: parsedRequest.value.overlapMinutes,
      pageSize: parsedRequest.value.pageSize,
      maxPages: parsedRequest.value.maxPages,
      defaultLookbackHours,
    },
    summary: {
      mappingsRequested: mappings.length,
      blockedSkippedCount,
      doneCount,
      partialCount,
      failedCount,
      totalPagesFetched,
      totalFramesFetched,
      totalTemperatureCandidates,
      totalHealthCandidates,
      totalTemperatureInserted,
      totalHealthInserted,
      totalDuplicatesIgnored,
      upstream403Count: totalUpstream403Count,
      totalErrors,
    },
    outcomes,
    observability,
  });
});
