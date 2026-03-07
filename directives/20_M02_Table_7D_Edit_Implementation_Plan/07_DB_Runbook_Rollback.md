# DB Runbook + Rollback (M02 temperature_logs edit)

## Forward migration
1. `supabase db push`
2. Zweryfikowac:
  - istnieja kolumny `edited_at`, `edited_by`, `edit_reason`
  - istnieje indeks `temperature_logs_sensor_recorded_at_desc_idx`
  - istnieja funkcje:
    - `update_temperature_log_value(uuid, numeric, text)`
    - `acknowledge_temperature_alert(uuid)`
  - policy `Logs updateable by all` nie istnieje

## Smoke tests SQL
- Pozytywny (manager/owner, rekord <= 7 dni, in-scope): update przechodzi.
- Negatywny (cook/cleaner): update blokowany.
- Negatywny (rekord > 7 dni): update blokowany.
- Negatywny (out-of-scope): update blokowany.

## Rollback
1. Przygotowac migracje rollback:
  - drop function `update_temperature_log_value`
  - drop function `acknowledge_temperature_alert` (jesli wracamy do direct update)
  - odtworzyc poprzednie policies (`Logs readable by all`, `Logs updateable by all`)
2. W awarii runtime:
  - hotfix aplikacji z read-only tabela
  - tymczasowo ukryc akcje edycji

## Uwaga
Rollback powinien byc ostatnia opcja. Preferowany jest fix-forward (korekta polityk/RPC).
