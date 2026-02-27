# S2 Findings (M08 Backend/DB) - Sprint 2

Data: 2026-02-27
Status: Implemented

## Zakres wykonany

1. Potwierdzony kontrakt `venues.nip`:
- Dozwolone: `NULL` albo 10 cyfr.
- Niedozwolone: pusty string, znaki nienumeryczne, inne d³ugoœci.

2. Storage `branding` hardening:
- Bucket `branding` jest tworzony/utrzymywany (`public=true`).
- Dodane policy na `storage.objects`:
  - `branding_select_kiosk_scope`
  - `branding_insert_manager_owner_kiosk_scope`
  - `branding_update_manager_owner_kiosk_scope`
  - `branding_delete_manager_owner_kiosk_scope`
- Scope œcie¿ki: `logos/<venue_id>/...`.
- Write tylko dla `manager/owner` w aktywnym `kiosk_sessions`.

3. Smoke SQL rozszerzony:
- pozytywny update `venues` z `name/address/logo_url`,
- readback `logo_url` + `nip`,
- test `nip = NULL` (kontrakt nullable),
- walidacja obecnoœci bucket `branding` i kompletu 4 policy.

## Format b³êdu backendowego (zamro¿ony)

Kontrakt diagnostyczny dla warstwy API/klienta:

- `M08_DB_CONSTRAINT`
  - warunek: SQLSTATE `23514` lub treœæ b³êdu zawiera nazwê check constraint (`venues_*_check`),
  - przyk³ady: `venues_nip_digits_check`, `venues_temp_interval_check`, `venues_temp_threshold_check`.

- `M08_DB_RLS_DENY`
  - warunek: SQLSTATE `42501` lub treœæ b³êdu zawiera `row-level security` / `permission denied`.

- `M08_STORAGE_DENY_OR_NOT_FOUND`
  - warunek: b³¹d z warstwy Storage (`storage.objects`) typu access denied, bucket/object not found.

Uwaga: mapowanie kodów do komunikatów u¿ytkownika jest wdra¿ane po stronie Frontendu w Sprincie 3.

## Zmienione pliki

- `supabase/migrations/20260227110000_m08_04_branding_storage_hardening.sql`
- `supabase/m08_04_settings_smoke_tests.sql`
