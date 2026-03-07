# Sprint 2 Dataset Spec (CCP-1 Temperature)

Data wykonania: 2026-02-22

## 1) Kontrakt repo -> provider -> PDF

Nowy kontrakt DTO znajduje sie w:
- `lib/features/m06_reports/repositories/reports_repository.dart`

Typy:
- `Ccp1TemperatureQuerySpec`
- `Ccp1TemperatureReportRow`
- `Ccp1TemperatureDataset`

## 2) Query spec

Funkcja:
- `buildCcp1TemperatureQuerySpec(DateTime month, String sensorId)`

Reguly:
- zakres dat:
  - `start = YYYY-MM-01 00:00:00.000`
  - `end = pierwszy_dzien_nastepnego_miesiaca - 1 ms`
- filtr:
  - tylko jeden `sensor_id`
- sortowanie:
  - `recorded_at ASC`

## 3) Dataset wynikowy

Funkcja:
- `getCcp1TemperatureDataset(month: ..., sensorId: ...)`

Zwraca:
- `sensorId`
- `sensorName` (z joina `sensors(name)`, fallback: `Sensor {sensorId}`)
- `month` (pierwszy dzien miesiaca)
- `rows: List<Ccp1TemperatureReportRow>`

## 4) Mapowanie rekordu do wiersza CCP-1

Funkcja:
- `mapTemperatureLogToCcp1Row(Map<String, dynamic> raw)`

Mapowanie:
- `date`: `dd.MM.yyyy`
- `time`: `HH:mm`
- `temperature`: `x.y°C` (1 miejsce po przecinku, np. `4.0°C`)
- `compliance`:
  - `TAK` dla `0.0 <= temperatura <= 4.0`
  - `NIE` dla `< 0.0` lub `> 4.0`
- `correctiveActions`: `''`
- `signature`: `''`

## 5) Integracja w providerze

Plik:
- `lib/features/m06_reports/providers/reports_provider.dart`

Zasady:
- sciezka `temperature` wymaga `sensorId` (1 sensor / raport)
- provider pobiera gotowy `Ccp1TemperatureDataset` z repo
- provider przekazuje do PDF gotowe kolumny i gotowe wiersze (`row.toPdfColumns()`)
- usunieta logika HTML (`HtmlReportGenerator`)

