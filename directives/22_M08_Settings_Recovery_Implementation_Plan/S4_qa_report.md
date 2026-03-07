# S4 QA Report (M08 Persistence) - Sprint 4

Data: 2026-02-27
Persona: The Nerd
Status: Completed (automaty + CLI DB E2E)

## 1. Matrix PASS/FAIL

| ID | Scenariusz | Status | Dowod |
|---|---|---|---|
| E2E-1 | Manager: zmiana `name/address`, save, refresh | PASS | CLI DB E2E: update + readback `name/address` persisted |
| E2E-2 | Manager: `nip` puste, save | PASS | Automaty + CLI DB E2E: `nip=NULL` po zapisie |
| E2E-3 | Manager: upload logo + save + odczyt logo | PASS | CLI DB E2E: upload `branding` HTTP 200 + public read HTTP 200 + `logo_url` persisted |
| E2E-4 | Cook: proba zapisu settings | PASS | CLI DB E2E: cook update denied |
| E2E-5 | Bledny `nip` | PASS | Automaty + CLI DB E2E: invalid `nip` blocked |
| E2E-6 | Awaria uploadu logo (symulacja) | PASS | CLI DB E2E: cook upload denied (HTTP 400) + testy mapowania bledow UI |

## 2. Wyniki testow automatycznych

Uruchomione:
- `C:\scr\flutter\bin\flutter.bat test test/features/m08_settings`

Wynik:
- **8 passed, 0 failed**

## 3. Wyniki testow DB/Storage przez CLI (staging)

Uruchomione:
- `supabase db push` (migracja `20260227110000_m08_04_branding_storage_hardening.sql`)
- skrypt E2E CLI: `supabase/.temp/run_m08_cli_e2e_v2.ps1`

Artefakt wynikow:
- `supabase/.temp/m08_cli_e2e_results.json`

Kluczowe wyniki:
- `E2E_1_name_persisted=true`
- `E2E_1_address_persisted=true`
- `E2E_2_nip_null=true`
- `E2E_3_logo_url_persisted=true`
- `E2E_3_manager_storage_upload_http=200`
- `E2E_3_public_logo_http=200`
- `E2E_4_cook_update_denied=true`
- `E2E_5_invalid_nip_blocked=true`
- `E2E_6_cook_storage_denied=true`
- `restore_error=null` (dane lokalu przywrocone)

## 4. Reprodukcja krytycznych przypadkow

### R-1: Invalid NIP
1. Wprowadz `nip` != 10 cyfr.
2. Kliknij `ZAPISZ USTAWIENIA`.
3. Oczekiwane: blokada UI lub DB reject (constraint).

### R-2: Logo upload deny
1. Uzyj roli `cook`.
2. Wybierz nowe logo i zapisz.
3. Oczekiwane: upload denied + brak falszywego sukcesu.

## 5. Logi i evidence

- Logi testow automatycznych: `flutter test` (8/8 PASS).
- Logi DB/Storage E2E: `supabase/.temp/m08_cli_e2e_results.json`.

## 6. Blokery / ryzyka

- Brak blockerow P0/P1 wykrytych w przebiegu Sprintu 4.
- Opcjonalny audit: dodatkowe uruchomienie `supabase/m08_04_settings_smoke_tests.sql` z real UUID.
