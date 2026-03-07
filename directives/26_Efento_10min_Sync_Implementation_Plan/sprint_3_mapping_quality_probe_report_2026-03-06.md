# Sprint 3 Mapping Quality Probe Report (2026-03-06)

## 1. Scope
Walidacja ryzyk Sprintu 3:
1. `S0-R3` - higiena metadanych `measurement_point_name`.
2. `S0-R2` - probe jakosci mapowania i danych dla `measurementPointId=1032261`.

## 2. Delivered artifacts
1. Migracja higieny mapowan:
   - `supabase/migrations/20260306170000_efento_04_mapping_hygiene_and_quality.sql`
2. Probe SQL 24h:
   - `supabase/efento_07_mapping_quality_probe.sql`

## 3. Migration coverage (`S0-R3`)
1. Sanitizacja rekordow `efento_measurement_point_map.measurement_point_name` dla:
   - `null`,
   - pustych wartosci,
   - wzorcow URL/secret-like (`http`, `secret=`, `x-haccp`, `bearer`).
2. Fallback nazwy: `Efento MP <measurement_point_id>`.
3. Wymuszenie write-time hygiene przez constraint:
   - `efento_map_measurement_point_name_hygiene_check`.

Status: `IMPLEMENTED` (wymaga uruchomienia migracji na runtime DB).

## 4. Probe coverage (`S0-R2`)
Probe dostarcza 4 sekcje:
1. Mapping snapshot (`1032261` + sensor + threshold venue).
2. Temperature quality summary 24h (`min/max/avg`, `outside_hard_range_count`, threshold/alarm stats).
3. Channel compliance summary 24h (oczekiwany kanal vs payload queue).
4. Overall `probe_decision` (`PASS` / `PARTIAL` / `FAIL`) + `decision_notes`.

Status: `IMPLEMENTED` (skrypt gotowy do uruchomienia na runtime DB).

## 5. Execution command (runtime)
Uruchom probe:
```sql
\i supabase/efento_07_mapping_quality_probe.sql
```
albo przez SQL editor projektu Supabase (staging/production).

## 6. Current sprint decision
- Decyzja: `PARTIAL`
- Uzasadnienie:
  1. implementacja Sprintu 3 jest dostarczona w repo,
  2. finalny status `PASS/FAIL` dla `1032261` wymaga uruchomienia probe na runtime DB i zapisania wynikow snapshot.

## 7. Exit criteria to close Sprint 3
1. Migracja `20260306170000_efento_04_mapping_hygiene_and_quality.sql` applied (`Local=Remote`).
2. Probe `supabase/efento_07_mapping_quality_probe.sql` uruchomiony na runtime.
3. Wynik `probe_decision` udokumentowany:
   - `PASS` lub
   - `PARTIAL/FAIL` z planem remediacji.
