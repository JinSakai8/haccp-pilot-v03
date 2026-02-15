-- 23_diagnostic_mismatch.sql
-- Cel: Debugowanie braku widoczności sensorów.
-- Sprawdź jakie strefy ma pracownik i jakie strefy mają sensory.

-- 1. Pokaż wszystkie strefy i ich ID
SELECT id, name, venue_id FROM zones;

-- 2. Pokaż powiązania pracownik-strefa (zobaczysz swoje ID)
SELECT ez.employee_id, ez.zone_id, z.name as zone_name
FROM employee_zones ez
JOIN zones z ON z.id = ez.zone_id;

-- 3. Pokaż sensory i ich strefy
SELECT s.id, s.name, s.zone_id, z.name as sensor_zone_name
FROM sensors s
LEFT JOIN zones z ON z.id = s.zone_id;

-- Jeśli ID z zapytania 2 (Twoja strefa) jest inne niż ID z zapytania 3 (Sensory) -> Mamy mismatch!
