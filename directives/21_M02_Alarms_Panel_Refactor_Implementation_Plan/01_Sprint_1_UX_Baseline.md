# Sprint 1: UX Baseline + Audit Freeze

## Cel
Zamknac decyzje UX i kontrakt danych dla sekcji alarmow przed implementacja.

## Wynik sprintu
- Potwierdzony gap UX (ListTile + brak `HaccpLongPressButton` + brak duration).
- Ustalony target layout dla kart aktywnych i historycznych.
- Zamrozony kontrakt `AlarmListItem`.

## Kontrakt `AlarmListItem`
- `logId`
- `sensorId`
- `sensorName`
- `temperature`
- `startedAt`
- `lastSeenAt`
- `durationMinutes`
- `isAcknowledged`
- `acknowledgedAt`
- `acknowledgedBy`

## Kryteria akceptacji
- Dokumentacyjnie zamkniete: stany `active/history/loading/empty/error`.
- Potwierdzona semantyka:
  - aktywne: `is_alert=true and is_acknowledged=false`
  - historia: `is_alert=true and is_acknowledged=true`
