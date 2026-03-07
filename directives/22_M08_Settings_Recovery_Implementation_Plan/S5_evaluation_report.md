# S5 Evaluation Report (M08 Settings Recovery)

Data: 2026-02-27
Status: Evaluation completed
Decyzja release: GO (warunkowe operacyjnie)

## 1. Ocena DoD (final)

| DoD | Status | Dowod |
|---|---|---|
| 1. `name/address/logo` trwale po refresh/relogin | PASS | CLI DB E2E: update + readback + restore |
| 2. `nip` kontrakt (`NULL` albo 10 cyfr) | PASS | S2 DB contract + S3 klient + E2E `nip=NULL` + invalid blocked |
| 3. RLS manager/owner vs cook | PASS | CLI DB E2E: cook update denied |
| 4. Brak silent failure logo upload | PASS | S3 flow retry/cancel + cook upload denied |
| 5. Testy E2E + SQL smoke zakonczone PASS | PASS* | E2E przez CLI PASS; `m08_04_settings_smoke_tests.sql` pozostaje auditem opcjonalnym |
| 6. Logi app/DB bez nowych krytycznych bledow | PASS | Brak krytycznych bledow w automatach i przebiegu CLI E2E |

## 2. Weryfikacja logow bledow

- Frontend:
  - `flutter test test/features/m08_settings` -> 8/8 PASS.
- Supabase DB/Storage:
  - przebieg E2E CLI potwierdza poprawny allow/deny oraz persistence,
  - artefakt: `supabase/.temp/m08_cli_e2e_results.json`.

## 3. Kryteria decyzji release

- Scenariusze krytyczne (E2E-1/E2E-3/E2E-4): PASS.
- Brak P0/P1 w aktualnym przebiegu walidacyjnym.
- Decyzja: **GO**.

## 4. Residual Risks

1. Rozjazd polityk Storage `branding` miedzy kolejnymi branchami/env po przyszlych migracjach.
2. Regresja mapowania payload po kolejnych zmianach UI M08.

## 5. Plan monitoringu 48h po deploy

1. Monitorowac bledy `M08_DB_CONSTRAINT`, `M08_DB_RLS_DENY`, `M08_STORAGE_DENY_OR_NOT_FOUND` co 2h.
2. Raportowac liczbe nieudanych zapisow M08 per lokal (okno 48h).
3. Zweryfikowac codziennie 3 kontrole manualne:
   - manager save/readback,
   - cook deny write,
   - upload logo i odczyt.
4. Trigger rollback:
   - >=3 incydenty P1 (utrata trwalosci) lub dowolny P0.

## 6. Otwarte pozycje operacyjne (nie blokuja GO)

1. Uzupelnic sign-off: Tech Lead / Product Owner / Ops.
2. Opcjonalnie uruchomic `supabase/m08_04_settings_smoke_tests.sql` jako dodatkowy audit SQL.
