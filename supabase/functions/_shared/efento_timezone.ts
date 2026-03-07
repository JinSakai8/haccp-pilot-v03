const WARSAW_TIME_ZONE = "Europe/Warsaw";

const warsawFormatter = new Intl.DateTimeFormat("en-GB", {
  timeZone: WARSAW_TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});

const warsawOffsetFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: WARSAW_TIME_ZONE,
  timeZoneName: "shortOffset",
});

type WallClockParts = {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
};

function parseWallClockParts(value: string): WallClockParts | null {
  const matched = /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/.exec(
    value.trim(),
  );
  if (!matched) {
    return null;
  }

  const parts = {
    year: Number.parseInt(matched[1], 10),
    month: Number.parseInt(matched[2], 10),
    day: Number.parseInt(matched[3], 10),
    hour: Number.parseInt(matched[4], 10),
    minute: Number.parseInt(matched[5], 10),
    second: Number.parseInt(matched[6], 10),
  };

  if (
    Number.isNaN(parts.year) ||
    Number.isNaN(parts.month) ||
    Number.isNaN(parts.day) ||
    Number.isNaN(parts.hour) ||
    Number.isNaN(parts.minute) ||
    Number.isNaN(parts.second)
  ) {
    return null;
  }

  return parts;
}

function getOffsetMinutes(utcDate: Date): number | null {
  const timeZonePart = warsawOffsetFormatter.formatToParts(utcDate).find((
    part,
  ) => part.type === "timeZoneName");
  const value = timeZonePart?.value ?? "";
  const matched = /^GMT([+-])(\d{1,2})(?::?(\d{2}))?$/.exec(value);
  if (!matched) {
    return null;
  }

  const sign = matched[1] === "-" ? -1 : 1;
  const hours = Number.parseInt(matched[2], 10);
  const minutes = matched[3] ? Number.parseInt(matched[3], 10) : 0;
  return sign * (hours * 60 + minutes);
}

function getRenderedWarsawParts(utcDate: Date): WallClockParts | null {
  const parts = warsawFormatter.formatToParts(utcDate);
  const lookup = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((part) => part.type === type)?.value;

  const year = Number.parseInt(lookup("year") ?? "", 10);
  const month = Number.parseInt(lookup("month") ?? "", 10);
  const day = Number.parseInt(lookup("day") ?? "", 10);
  const hour = Number.parseInt(lookup("hour") ?? "", 10);
  const minute = Number.parseInt(lookup("minute") ?? "", 10);
  const second = Number.parseInt(lookup("second") ?? "", 10);

  if (
    Number.isNaN(year) ||
    Number.isNaN(month) ||
    Number.isNaN(day) ||
    Number.isNaN(hour) ||
    Number.isNaN(minute) ||
    Number.isNaN(second)
  ) {
    return null;
  }

  return { year, month, day, hour, minute, second };
}

function partsEqual(left: WallClockParts, right: WallClockParts): boolean {
  return left.year === right.year &&
    left.month === right.month &&
    left.day === right.day &&
    left.hour === right.hour &&
    left.minute === right.minute &&
    left.second === right.second;
}

export function parseEfentoWarsawWallClockToUtcIso(
  value: unknown,
): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return null;
  }

  const wallClock = parseWallClockParts(trimmed);
  if (!wallClock) {
    const fallback = new Date(trimmed);
    if (Number.isNaN(fallback.getTime())) {
      return null;
    }
    return fallback.toISOString();
  }

  let candidateMs = Date.UTC(
    wallClock.year,
    wallClock.month - 1,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
  );

  for (let attempt = 0; attempt < 4; attempt += 1) {
    const offsetMinutes = getOffsetMinutes(new Date(candidateMs));
    if (offsetMinutes === null) {
      return null;
    }

    const correctedMs = Date.UTC(
      wallClock.year,
      wallClock.month - 1,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
    ) - offsetMinutes * 60 * 1000;

    if (correctedMs === candidateMs) {
      break;
    }
    candidateMs = correctedMs;
  }

  const utcDate = new Date(candidateMs);
  const rendered = getRenderedWarsawParts(utcDate);
  if (!rendered || !partsEqual(rendered, wallClock)) {
    return null;
  }

  return utcDate.toISOString();
}
