# Sprint 1 — Analysis: Data Flow Audit (M08 Persistence)

## 1. Cel sprintu
Udokumentować rzeczywisty przepływ danych i zlokalizować punkty awarii zapisu `name/address/logo`.

## 2. Pliki do przeszukania (obowiązkowe)
- `lib/features/m08_settings/screens/global_settings_screen.dart`
- `lib/features/m08_settings/providers/m08_providers.dart`
- `lib/features/m08_settings/repositories/venue_repository.dart`
- `lib/core/providers/auth_provider.dart`
- `lib/features/m01_auth/screens/zone_selection_screen.dart`
- `lib/core/services/supabase_service.dart`
- `supabase/migrations/20260224113000_m08_01_venues_settings_columns.sql`
- `supabase/migrations/20260224114000_m08_02_venues_rls_update_policy.sql`
- `supabase/m08_04_settings_smoke_tests.sql`

## 3. Narzędzia i komendy discovery
- `rg -n "saveSettings|updateSettings|uploadLogoBytes|logo_url|nip|temp_interval|temp_threshold" lib`
- `rg -n "venues_nip_digits_check|venues_temp_|create policy|kiosk_sessions" supabase/migrations`
- `rg -n "branding|storage.objects|bucket_id" supabase baseline_schema.sql`

## 4. Checklist audytowa
| Obszar | Co sprawdzić | Oczekiwany wynik |
|---|---|---|
| Form state | Jak normalizowany jest `nip` | Puste `nip` -> `NULL`, nie `''` |
| Submit path | Czy submit robi atomiczny flow i obsługuje błędy | Brak silent fail |
| Provider state | Czy po zapisie następuje readback/refresh | UI pokazuje persisted values |
| Repo payload | Czy pola mapują 1:1 na kolumny `venues` | Brak błędnych kluczy/typów |
| DB schema | Constrainty i wartości dozwolone | Zgodne z walidacją UI |
| RLS | Czy manager/owner może update, cook nie może | Deterministyczny wynik |
| Storage logo | Bucket/policies/public URL/path | Upload i odczyt działają |

## 5. Artefakt sprintu (wymagany)
Raport `S1_findings.md` z:
1. data flow diagram (tekstowy),
2. lista root causes (potwierdzone vs hipotezy),
3. matrix: symptom -> przyczyna -> dowód (plik/linia).

## 6. Definition of Done Sprintu 1
- Root cause #1 potwierdzony testowalnie.
- Lista zmian na S2/S3 jest zamrożona (no open decisions).
