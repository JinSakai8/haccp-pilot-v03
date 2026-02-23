# Sprint 2: UI Alarm Cards Refactor

## Cel
Przebudowac `alarms_panel_screen.dart` na dedykowane karty alarmowe zgodne z UX spec.

## Zakres
- Zamiana `ListTile` na custom card layout.
- TopBar: tytul `Alarmy` + Back do 2.1.
- Taby: `AKTYWNE` i `HISTORIA`.
- Active card:
  - `sensorName`
  - temperatura (`24sp`, czerwien)
  - `Od: HH:mm (duration)`
  - `Ostatni odczyt`
  - `HaccpLongPressButton` -> `Przyjalem do wiadomosci`
- History card:
  - badge `Potwierdzono`
  - `acknowledged_at`
  - `acknowledged_by` (skrot)
- Empty state per tab (`HaccpEmptyState`).

## Kryteria akceptacji
- Brak overflow dla `360x800`.
- ACK przycisk jest tylko na tabie aktywnym.
- Tytul i hierarchia informacji sa czytelne dla operatora.
