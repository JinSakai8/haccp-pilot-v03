import { createClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";
import {
  buildObservabilitySnapshot,
  loadAlertThresholdsFromEnv,
} from "../_shared/efento_observability.ts";

type SchedulerRequest = {
  dryRun?: boolean;
  runWorker?: boolean;
  runBackfill?: boolean;
  includeObservability?: boolean;
  backfillIncludeBlocked?: boolean;
  workerBatchSize?: number;
  workerMeasurementPointId?: number;
  backfillMeasurementPointId?: number;
  backfillFrom?: string;
  backfillTo?: string;
  backfillOverlapMinutes?: number;
  backfillPageSize?: number;
  backfillMaxPages?: number;
};

type InvocationResult = {
  endpoint: "efento-worker" | "efento-backfill";
  attempted: boolean;
  ok: boolean;
  transportOk: boolean;
  pipelineOk: boolean;
  status: number | null;
  body: unknown;
  businessError: string | null;
  error: string | null;
};

const JSON_HEADERS: HeadersInit = {
  "content-type": "application/json; charset=utf-8",
};

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

function parseTimestamp(value: unknown): string | null {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed.toISOString();
}

function truncateErrorMessage(value: unknown): string {
  const fallback = "unknown_scheduler_error";
  const message = value instanceof Error
    ? value.message
    : typeof value === "string"
    ? value
    : fallback;
  return message.length > 900 ? `${message.slice(0, 897)}...` : message;
}

function resolveInvocationPipelineState(
  body: unknown,
  transportOk: boolean,
): { pipelineOk: boolean; businessError: string | null } {
  if (!transportOk) {
    return {
      pipelineOk: false,
      businessError: null,
    };
  }

  const objectBody = asObject(body);
  if (!objectBody) {
    return {
      pipelineOk: true,
      businessError: null,
    };
  }

  if (!Object.prototype.hasOwnProperty.call(objectBody, "ok")) {
    return {
      pipelineOk: true,
      businessError: null,
    };
  }

  if (objectBody.ok === false) {
    const bodyError =
      typeof objectBody.error === "string" && objectBody.error.trim().length > 0
        ? objectBody.error
        : typeof objectBody.message === "string" &&
            objectBody.message.trim().length > 0
        ? objectBody.message
        : "downstream_ok_false";
    return {
      pipelineOk: false,
      businessError: bodyError,
    };
  }

  return {
    pipelineOk: true,
    businessError: null,
  };
}

function resolveFunctionsBaseUrl(requestUrl: URL): string {
  const rawSupabaseUrl = Deno.env.get("SUPABASE_URL");
  if (typeof rawSupabaseUrl === "string" && rawSupabaseUrl.trim().length > 0) {
    try {
      const parsed = new URL(rawSupabaseUrl.trim());
      return parsed.origin;
    } catch {
      console.error(
        "efento-scheduler: invalid SUPABASE_URL, fallback to request origin",
      );
    }
  }
  return requestUrl.origin;
}

function parseSchedulerRequest(rawBody: unknown): {
  ok: true;
  value: {
    dryRun: boolean;
    runWorker: boolean;
    runBackfill: boolean;
    includeObservability: boolean;
    backfillIncludeBlocked: boolean;
    workerBatchSize: number;
    workerMeasurementPointId: number | null;
    backfillMeasurementPointId: number | null;
    backfillFrom: string | null;
    backfillTo: string | null;
    backfillOverlapMinutes: number;
    backfillPageSize: number;
    backfillMaxPages: number;
  };
} | { ok: false; error: string } {
  const body = asObject(rawBody) ?? {};

  const dryRun = body.dryRun === true;
  const runWorker = body.runWorker !== false;
  const runBackfill = body.runBackfill !== false;
  const includeObservability = body.includeObservability !== false;
  let backfillIncludeBlocked = false;
  if (body.backfillIncludeBlocked !== undefined) {
    if (typeof body.backfillIncludeBlocked !== "boolean") {
      return { ok: false, error: "backfillIncludeBlocked must be a boolean." };
    }
    backfillIncludeBlocked = body.backfillIncludeBlocked;
  }

  let workerBatchSize = 100;
  if (body.workerBatchSize !== undefined) {
    const parsed = toPositiveInteger(body.workerBatchSize);
    if (parsed === null) {
      return {
        ok: false,
        error: "workerBatchSize must be a positive integer.",
      };
    }
    workerBatchSize = Math.min(parsed, 500);
  }

  let workerMeasurementPointId: number | null = null;
  if (body.workerMeasurementPointId !== undefined) {
    const parsed = toPositiveInteger(body.workerMeasurementPointId);
    if (parsed === null) {
      return {
        ok: false,
        error: "workerMeasurementPointId must be a positive integer.",
      };
    }
    workerMeasurementPointId = parsed;
  }

  let backfillMeasurementPointId: number | null = null;
  if (body.backfillMeasurementPointId !== undefined) {
    const parsed = toPositiveInteger(body.backfillMeasurementPointId);
    if (parsed === null) {
      return {
        ok: false,
        error: "backfillMeasurementPointId must be a positive integer.",
      };
    }
    backfillMeasurementPointId = parsed;
  }

  const backfillFrom = body.backfillFrom === undefined
    ? null
    : parseTimestamp(body.backfillFrom);
  const backfillTo = body.backfillTo === undefined
    ? null
    : parseTimestamp(body.backfillTo);

  if (body.backfillFrom !== undefined && backfillFrom === null) {
    return {
      ok: false,
      error: "backfillFrom must be a valid ISO-8601 timestamp.",
    };
  }
  if (body.backfillTo !== undefined && backfillTo === null) {
    return {
      ok: false,
      error: "backfillTo must be a valid ISO-8601 timestamp.",
    };
  }
  if (
    backfillFrom && backfillTo &&
    new Date(backfillFrom).getTime() > new Date(backfillTo).getTime()
  ) {
    return {
      ok: false,
      error: "backfillFrom cannot be later than backfillTo.",
    };
  }

  let backfillOverlapMinutes = 15;
  if (body.backfillOverlapMinutes !== undefined) {
    const parsed = toPositiveInteger(body.backfillOverlapMinutes);
    if (parsed === null) {
      return {
        ok: false,
        error: "backfillOverlapMinutes must be a positive integer.",
      };
    }
    backfillOverlapMinutes = Math.min(parsed, 12 * 60);
  }

  let backfillPageSize = 200;
  if (body.backfillPageSize !== undefined) {
    const parsed = toPositiveInteger(body.backfillPageSize);
    if (parsed === null) {
      return {
        ok: false,
        error: "backfillPageSize must be a positive integer.",
      };
    }
    backfillPageSize = Math.min(parsed, 1000);
  }

  let backfillMaxPages = 20;
  if (body.backfillMaxPages !== undefined) {
    const parsed = toPositiveInteger(body.backfillMaxPages);
    if (parsed === null) {
      return {
        ok: false,
        error: "backfillMaxPages must be a positive integer.",
      };
    }
    backfillMaxPages = Math.min(parsed, 500);
  }

  return {
    ok: true,
    value: {
      dryRun,
      runWorker,
      runBackfill,
      includeObservability,
      backfillIncludeBlocked,
      workerBatchSize,
      workerMeasurementPointId,
      backfillMeasurementPointId,
      backfillFrom,
      backfillTo,
      backfillOverlapMinutes,
      backfillPageSize,
      backfillMaxPages,
    },
  };
}

async function invokeFunction(params: {
  origin: string;
  endpoint: "efento-worker" | "efento-backfill";
  secretHeader: string;
  secretValue: string;
  body: Record<string, unknown>;
}): Promise<InvocationResult> {
  const endpointUrl = `${params.origin}/functions/v1/${params.endpoint}`;
  try {
    const response = await fetch(endpointUrl, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        [params.secretHeader]: params.secretValue,
      },
      body: JSON.stringify(params.body),
      signal: AbortSignal.timeout(120000),
    });

    let body: unknown = null;
    try {
      body = await response.json();
    } catch {
      body = await response.text();
    }

    const transportOk = response.ok;
    const pipelineState = resolveInvocationPipelineState(body, transportOk);

    return {
      endpoint: params.endpoint,
      attempted: true,
      ok: transportOk,
      transportOk,
      pipelineOk: pipelineState.pipelineOk,
      status: response.status,
      body,
      businessError: pipelineState.businessError,
      error: transportOk ? null : `http_${response.status}`,
    };
  } catch (error) {
    return {
      endpoint: params.endpoint,
      attempted: true,
      ok: false,
      transportOk: false,
      pipelineOk: false,
      status: null,
      body: null,
      businessError: null,
      error: truncateErrorMessage(error),
    };
  }
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

  const schedulerSecret = normalizeSecret(
    Deno.env.get("EFENTO_SCHEDULER_SECRET"),
  );
  if (!schedulerSecret) {
    console.error("efento-scheduler: missing EFENTO_SCHEDULER_SECRET");
    return jsonResponse(500, {
      error: "server_misconfigured",
      message: "Scheduler secret is not configured.",
    });
  }

  const requestUrl = new URL(request.url);
  const headerSecret = normalizeSecret(
    request.headers.get("x-haccp-scheduler-secret"),
  );
  const querySecret = normalizeSecret(requestUrl.searchParams.get("secret"));
  const queryFallbackEnabled = isQuerySecretFallbackEnabled();

  const providedSecret = headerSecret ??
    (queryFallbackEnabled ? querySecret : null);

  if (!headerSecret && querySecret && !queryFallbackEnabled) {
    return jsonResponse(401, {
      error: "unauthorized",
      message:
        "Query-string secret is disabled. Use X-HACCP-Scheduler-Secret header.",
    });
  }

  if (!providedSecret) {
    return jsonResponse(401, {
      error: "unauthorized",
      message: "Scheduler secret is required.",
    });
  }
  if (providedSecret !== schedulerSecret) {
    return jsonResponse(403, {
      error: "forbidden",
      message: "Invalid scheduler secret.",
    });
  }

  let body: SchedulerRequest | null = null;
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

  const parsedRequest = parseSchedulerRequest(body);
  if (!parsedRequest.ok) {
    return jsonResponse(400, {
      error: "invalid_request",
      message: parsedRequest.error,
    });
  }

  const workerSecret = normalizeSecret(Deno.env.get("EFENTO_WORKER_SECRET"));
  const backfillSecret = normalizeSecret(
    Deno.env.get("EFENTO_BACKFILL_SECRET"),
  );

  if (parsedRequest.value.runWorker && !workerSecret) {
    return jsonResponse(500, {
      error: "server_misconfigured",
      message: "EFENTO_WORKER_SECRET is missing.",
    });
  }

  if (parsedRequest.value.runBackfill && !backfillSecret) {
    return jsonResponse(500, {
      error: "server_misconfigured",
      message: "EFENTO_BACKFILL_SECRET is missing.",
    });
  }

  const functionsBaseUrl = resolveFunctionsBaseUrl(requestUrl);
  const invocations: InvocationResult[] = [];

  if (parsedRequest.value.runWorker && workerSecret) {
    const workerBody: Record<string, unknown> = {
      batchSize: parsedRequest.value.workerBatchSize,
      dryRun: parsedRequest.value.dryRun,
    };
    if (parsedRequest.value.workerMeasurementPointId !== null) {
      workerBody.measurementPointId =
        parsedRequest.value.workerMeasurementPointId;
    }
    invocations.push(
      await invokeFunction({
        origin: functionsBaseUrl,
        endpoint: "efento-worker",
        secretHeader: "x-haccp-worker-secret",
        secretValue: workerSecret,
        body: workerBody,
      }),
    );
  } else {
    invocations.push({
      endpoint: "efento-worker",
      attempted: false,
      ok: true,
      transportOk: true,
      pipelineOk: true,
      status: null,
      body: { skipped: true, reason: "runWorker=false" },
      businessError: null,
      error: null,
    });
  }

  if (parsedRequest.value.runBackfill && backfillSecret) {
    const backfillBody: Record<string, unknown> = {
      dryRun: parsedRequest.value.dryRun,
      includeBlocked: parsedRequest.value.backfillIncludeBlocked,
      overlapMinutes: parsedRequest.value.backfillOverlapMinutes,
      pageSize: parsedRequest.value.backfillPageSize,
      maxPages: parsedRequest.value.backfillMaxPages,
    };
    if (parsedRequest.value.backfillMeasurementPointId !== null) {
      backfillBody.measurementPointId =
        parsedRequest.value.backfillMeasurementPointId;
    }
    if (parsedRequest.value.backfillFrom) {
      backfillBody.from = parsedRequest.value.backfillFrom;
    }
    if (parsedRequest.value.backfillTo) {
      backfillBody.to = parsedRequest.value.backfillTo;
    }
    invocations.push(
      await invokeFunction({
        origin: functionsBaseUrl,
        endpoint: "efento-backfill",
        secretHeader: "x-haccp-backfill-secret",
        secretValue: backfillSecret,
        body: backfillBody,
      }),
    );
  } else {
    invocations.push({
      endpoint: "efento-backfill",
      attempted: false,
      ok: true,
      transportOk: true,
      pipelineOk: true,
      status: null,
      body: { skipped: true, reason: "runBackfill=false" },
      businessError: null,
      error: null,
    });
  }

  let observability: unknown = null;
  if (parsedRequest.value.includeObservability) {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      observability = {
        error:
          "SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are required for observability snapshot.",
      };
    } else {
      try {
        const supabase = createClient(supabaseUrl, serviceRoleKey, {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        });
        observability = await buildObservabilitySnapshot({
          supabase,
          thresholds: loadAlertThresholdsFromEnv(),
        });
      } catch (error) {
        observability = {
          error: truncateErrorMessage(error),
        };
      }
    }
  }

  const attemptedInvocations = invocations.filter((item) => item.attempted);
  const hasAttemptedInvocation = attemptedInvocations.length > 0;
  const transportOk = !hasAttemptedInvocation ||
    attemptedInvocations.every((item) => item.transportOk);
  const pipelineOk = !hasAttemptedInvocation ||
    attemptedInvocations.every((item) => item.pipelineOk);
  const degraded = hasAttemptedInvocation && transportOk && !pipelineOk;
  const degradationReasons = attemptedInvocations
    .filter((item) => !item.pipelineOk)
    .map((item) =>
      item.businessError ?? item.error ?? "downstream_pipeline_failure"
    );

  console.log("efento-scheduler: run completed", {
    dryRun: parsedRequest.value.dryRun,
    functionsBaseUrl,
    transportOk,
    pipelineOk,
    degraded,
    degradationReasons,
    invocations: invocations.map((item) => ({
      endpoint: item.endpoint,
      attempted: item.attempted,
      ok: item.ok,
      transportOk: item.transportOk,
      pipelineOk: item.pipelineOk,
      status: item.status,
      businessError: item.businessError,
      error: item.error,
    })),
  });

  return jsonResponse(transportOk ? 200 : 502, {
    ok: pipelineOk,
    transportOk,
    pipelineOk,
    degraded,
    degradationReasons,
    dryRun: parsedRequest.value.dryRun,
    request: parsedRequest.value,
    invocations,
    observability,
  });
});
