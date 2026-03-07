import { parseEfentoWarsawWallClockToUtcIso } from "./efento_timezone.ts";

Deno.test("parses winter Warsaw wall clock to UTC", () => {
  const result = parseEfentoWarsawWallClockToUtcIso("2026-03-07 15:20:00");

  if (result !== "2026-03-07T14:20:00.000Z") {
    throw new Error(`Unexpected result: ${result}`);
  }
});

Deno.test("parses summer Warsaw wall clock to UTC with DST", () => {
  const result = parseEfentoWarsawWallClockToUtcIso("2026-07-07 15:20:00");

  if (result !== "2026-07-07T13:20:00.000Z") {
    throw new Error(`Unexpected result: ${result}`);
  }
});

Deno.test("keeps ISO timestamps with zone intact", () => {
  const result = parseEfentoWarsawWallClockToUtcIso("2026-03-07T14:20:00.000Z");

  if (result !== "2026-03-07T14:20:00.000Z") {
    throw new Error(`Unexpected result: ${result}`);
  }
});
