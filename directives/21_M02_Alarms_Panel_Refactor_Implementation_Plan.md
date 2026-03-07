# Plan Implementacji M02 -> Refactor Sekcji Alarmow (Index)

Pakiet wdrozeniowy dla przebudowy sekcji alarmow w `m02_monitoring` zgodnie z UX spec i architektura kiosk.

## Cel
- Przywrocic czytelnosc i ergonomie panelu alarmow.
- Ujednolicic kontrakt danych pod UI (DTO + RPC read-model).
- Utrzymac ACK przez RPC i zgodnosc z zasadami `HaccpLongPressButton`.

## Zakres
- UI: `lib/features/m02_monitoring/screens/alarms_panel_screen.dart`
- Data: `lib/features/m02_monitoring/repositories/measurements_repository.dart`
- State: `lib/features/m02_monitoring/providers/monitoring_provider.dart`
- Model: `lib/features/m02_monitoring/models/alarm_list_item.dart`
- DB: nowy RPC `get_temperature_alarms(...)`
- Testy: widget/regresja sekcji alarmow

## Decyzje zamrozone
1. Brak nowej tabeli alarmow, zrodlo: `temperature_logs`.
2. ACK pozostaje przez `acknowledge_temperature_alert(...)`.
3. Read path alarmow idzie przez dedykowany RPC.
4. UI renderuje `AlarmListItem` (nie surowy `TemperatureLog`).
5. Numeracja sprintow od `1` (bez Sprint 0).

## Definicja sukcesu
- Ekran alarmow ma czytelne karty i brak overflow dla szerokosci `360px`.
- ACK wymaga long press 1s i blokuje duplikaty w trakcie zapisu.
- `alarmsProvider` zwraca komplet danych z jednego read path.
- Testy M02 przechodza bez regresji.

## Podzial na sprinty
1. `directives/21_M02_Alarms_Panel_Refactor_Implementation_Plan/01_Sprint_1_UX_Baseline.md`
2. `directives/21_M02_Alarms_Panel_Refactor_Implementation_Plan/02_Sprint_2_UI_Alarm_Cards.md`
3. `directives/21_M02_Alarms_Panel_Refactor_Implementation_Plan/03_Sprint_3_DB_RPC_Data_Contract.md`
4. `directives/21_M02_Alarms_Panel_Refactor_Implementation_Plan/04_Sprint_4_ACK_Interaction_State.md`
5. `directives/21_M02_Alarms_Panel_Refactor_Implementation_Plan/05_Sprint_5_Testing_QA_Release.md`
