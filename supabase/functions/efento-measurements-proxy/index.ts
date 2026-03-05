const JSON_HEADERS: HeadersInit = {
  "content-type": "application/json; charset=utf-8",
};

type EventRow = {
  timestampIso: string;
  status: string;
  period: number | null;
  value: number | null;
};

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  });
}

function asObject(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function toPositiveInteger(value: unknown): number | null {
  if (typeof value === "number" && Number.isInteger(value) && value > 0) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number.parseInt(value, 10);
    if (Number.isInteger(parsed) && parsed > 0) {
      return parsed;
    }
  }
  return null;
}

function parseIncomingIso(value: string | null): Date | null {
  if (!value) {
    return null;
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed;
}

function twoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function formatEfentoDateTimeUtc(value: Date): string {
  return `${value.getUTCFullYear()}-${twoDigits(value.getUTCMonth() + 1)}-${twoDigits(value.getUTCDate())} ${
    twoDigits(value.getUTCHours())
  }:${twoDigits(value.getUTCMinutes())}:${twoDigits(value.getUTCSeconds())}`;
}

function parseEfentoDateTimeToIso(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return null;
  }

  const matched = /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/.exec(trimmed);
  if (matched) {
    const year = Number.parseInt(matched[1], 10);
    const month = Number.parseInt(matched[2], 10);
    const day = Number.parseInt(matched[3], 10);
    const hour = Number.parseInt(matched[4], 10);
    const minute = Number.parseInt(matched[5], 10);
    const second = Number.parseInt(matched[6], 10);
    return new Date(Date.UTC(year, month - 1, day, hour, minute, second)).toISOString();
  }

  const fallback = new Date(trimmed);
  if (Number.isNaN(fallback.getTime())) {
    return null;
  }
  return fallback.toISOString();
}

function extractApiToken(request: Request): string | null {
  const directToken = request.headers.get("x-efento-api-token")?.trim();
  if (directToken) {
    return directToken;
  }

  const authorization = request.headers.get("authorization")?.trim();
  if (!authorization) {
    return null;
  }

  const bearerPrefix = /^Bearer\s+/i;
  if (bearerPrefix.test(authorization)) {
    const token = authorization.replace(bearerPrefix, "").trim();
    return token.length > 0 ? token : null;
  }
  return authorization;
}

function truncate(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }
  return `${value.slice(0, Math.max(0, maxLength - 3))}...`;
}

function buildTypeMap(measurementPoint: Record<string, unknown> | null): Map<number, string> {
  const map = new Map<number, string>();
  if (!measurementPoint) {
    return map;
  }

  const sources = [
    asObject(measurementPoint.device),
    asObject(measurementPoint.measurements),
  ].filter((entry): entry is Record<string, unknown> => entry !== null);

  for (const source of sources) {
    const channels = Array.isArray(source.channels) ? source.channels : [];
    for (const channelRaw of channels) {
      const channel = asObject(channelRaw);
      if (!channel) {
        continue;
      }
      const number = toPositiveInteger(channel.number);
      const type = typeof channel.type === "string" ? channel.type.trim().toUpperCase() : "";
      if (number && type.length > 0) {
        map.set(number, type);
      }
    }
  }

  return map;
}

function buildFrame(upstreamPayload: Record<string, unknown>, fallbackMeasurementPointId: number):
  | { ok: true; value: Record<string, unknown> | null; measurementsCount: number }
  | { ok: false; error: string } {
  const measurements = Array.isArray(upstreamPayload.measurements) ? upstreamPayload.measurements : null;
  if (!measurements) {
    return { ok: false, error: "Upstream payload does not include measurements array." };
  }

  if (measurements.length === 0) {
    return { ok: true, value: null, measurementsCount: 0 };
  }

  const measurementPoint = asObject(upstreamPayload.measurementPoint);
  const measurementPointId = toPositiveInteger(measurementPoint?.id) ?? fallbackMeasurementPointId;
  if (measurementPointId <= 0) {
    return { ok: false, error: "Cannot resolve measurementPointId from upstream payload." };
  }

  const measuredByDevices = Array.isArray(upstreamPayload.measuredByDevices) ? upstreamPayload.measuredByDevices : [];
  const measuredByDevice = measuredByDevices
    .map((entry) => asObject(entry))
    .find((entry): entry is Record<string, unknown> => entry !== null);

  const device = asObject(measurementPoint?.device);
  const deviceSerialNumber = typeof device?.serialNumber === "string" && device.serialNumber.trim().length > 0
    ? device.serialNumber.trim()
    : (typeof measuredByDevice?.serialNumber === "string" && measuredByDevice.serialNumber.trim().length > 0
      ? measuredByDevice.serialNumber.trim()
      : `EFENTO-${measurementPointId}`);

  const channelTypeMap = buildTypeMap(measurementPoint);
  const eventsByChannel = new Map<number, EventRow[]>();

  let firstMs: number | null = null;
  let lastMs: number | null = null;

  for (const rowRaw of measurements) {
    const row = asObject(rowRaw);
    if (!row) {
      continue;
    }

    const measuredAtIso = parseEfentoDateTimeToIso(row.measuredAt);
    if (!measuredAtIso) {
      continue;
    }
    const measuredAtMs = new Date(measuredAtIso).getTime();
    if (firstMs === null || measuredAtMs < firstMs) {
      firstMs = measuredAtMs;
    }
    if (lastMs === null || measuredAtMs > lastMs) {
      lastMs = measuredAtMs;
    }

    const period = toPositiveInteger(row.period);
    const channels = Array.isArray(row.channels) ? row.channels : [];

    for (const channelRaw of channels) {
      const channel = asObject(channelRaw);
      if (!channel) {
        continue;
      }
      const channelNumber = toPositiveInteger(channel.number);
      if (!channelNumber) {
        continue;
      }

      const existing = eventsByChannel.get(channelNumber) ?? [];
      const value = typeof channel.value === "number" && Number.isFinite(channel.value) ? channel.value : null;
      const status = typeof channel.status === "string" && channel.status.trim().length > 0
        ? channel.status.trim().toUpperCase()
        : "UNKNOWN";
      existing.push({
        timestampIso: measuredAtIso,
        status,
        period,
        value,
      });
      eventsByChannel.set(channelNumber, existing);
    }
  }

  if (firstMs === null || lastMs === null) {
    return { ok: true, value: null, measurementsCount: measurements.length };
  }

  const measurementsEvents = Array.from(eventsByChannel.entries())
    .sort((a, b) => a[0] - b[0])
    .map(([channelNumber, events]) => {
      events.sort((a, b) => new Date(a.timestampIso).getTime() - new Date(b.timestampIso).getTime());
      const hasNumericValue = events.some((event) => typeof event.value === "number");
      const channelType = channelTypeMap.get(channelNumber) ?? (hasNumericValue ? "TEMPERATURE" : "UNKNOWN");
      return {
        channelNumber,
        channelType,
        events: events.map((event) => ({
          timestamp: event.timestampIso,
          status: event.status,
          period: event.period,
          value: event.value,
        })),
      };
    });

  if (measurementsEvents.length === 0) {
    return { ok: true, value: null, measurementsCount: measurements.length };
  }

  return {
    ok: true,
    value: {
      measurementPointId: measurementPointId,
      deviceSerialNumber,
      firstMeasurementTimestamp: new Date(firstMs).toISOString(),
      lastMeasurementTimestamp: new Date(lastMs).toISOString(),
      measurementsEvents,
    },
    measurementsCount: measurements.length,
  };
}

Deno.serve(async (request) => {
  if (request.method !== "GET") {
    return jsonResponse(405, {
      error: "method_not_allowed",
      message: "Only GET is supported.",
    });
  }

  const apiToken = extractApiToken(request);
  if (!apiToken) {
    return jsonResponse(401, {
      error: "missing_api_token",
      message: "Missing Efento API token in authorization or x-efento-api-token header.",
    });
  }

  const url = new URL(request.url);
  const measurementPointId = toPositiveInteger(url.searchParams.get("measurementPointId"));
  if (!measurementPointId) {
    return jsonResponse(400, {
      error: "invalid_measurement_point_id",
      message: "measurementPointId must be a positive integer.",
    });
  }

  const fromDate = parseIncomingIso(url.searchParams.get("from"));
  const toDate = parseIncomingIso(url.searchParams.get("to"));
  if (!fromDate || !toDate) {
    return jsonResponse(400, {
      error: "invalid_window",
      message: "from/to must be ISO-8601 date-time strings.",
    });
  }

  if (fromDate.getTime() > toDate.getTime()) {
    return jsonResponse(400, {
      error: "invalid_window",
      message: "from cannot be later than to.",
    });
  }

  const upstreamUrl = new URL(`https://cloud.efento.io/api/v2/measurement-points/${measurementPointId}/measurements`);
  upstreamUrl.searchParams.set("from", formatEfentoDateTimeUtc(fromDate));
  upstreamUrl.searchParams.set("to", formatEfentoDateTimeUtc(toDate));

  const upstreamResponse = await fetch(upstreamUrl, {
    method: "GET",
    headers: {
      accept: "application/json",
      authorization: apiToken,
      "x-efento-api-token": apiToken,
    },
    signal: AbortSignal.timeout(20000),
  });

  const responseText = await upstreamResponse.text();
  let parsedPayload: unknown = null;
  if (responseText.trim().length > 0) {
    try {
      parsedPayload = JSON.parse(responseText);
    } catch {
      parsedPayload = null;
    }
  }

  if (!upstreamResponse.ok) {
    return jsonResponse(upstreamResponse.status, {
      error: "upstream_error",
      message: "Efento API returned non-success response.",
      upstreamStatus: upstreamResponse.status,
      upstreamBodyPreview: truncate(responseText, 400),
    });
  }

  const objectPayload = asObject(parsedPayload);
  if (!objectPayload) {
    return jsonResponse(502, {
      error: "invalid_upstream_payload",
      message: "Efento API payload is not a JSON object.",
    });
  }

  const frame = buildFrame(objectPayload, measurementPointId);
  if (!frame.ok) {
    return jsonResponse(502, {
      error: "invalid_upstream_payload",
      message: frame.error,
    });
  }

  const items = frame.value ? [frame.value] : [];
  return jsonResponse(200, {
    items,
    nextPageToken: null,
    proxied: true,
    upstreamMeasurementsCount: frame.measurementsCount,
    measurementPointId,
    fromIso: fromDate.toISOString(),
    toIso: toDate.toISOString(),
  });
});
