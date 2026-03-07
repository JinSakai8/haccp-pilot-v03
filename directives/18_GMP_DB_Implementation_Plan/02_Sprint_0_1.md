# Sprint 0-1 (Foundation + Contract Fix)

## Sprint 0: Baseline i bezpieczeństwo zmian (0.5-1 dzień)

### Cel
Przygotować punkt kontrolny przed zmianami (kod + schema + dane).

### Zadania
- [x] S0.1 Utworzyć branch `hotfix/gmp-db-audit`.
- [x] S0.2 Zrzucić schemat (`supabase db pull`) i porównać z SQL w repo.
  - Status końcowy (2026-02-22): wykonano poprawny `supabase db pull`; pełny zrzut jest w
    `supabase/migrations/20260222084803_remote_schema.sql` oraz `baseline_schema.sql`.
- [x] S0.3 Snapshot diagnostyczny `haccp_logs`:
  - liczba rekordów per `form_id`,
  - liczba rekordów z `zone_id IS NULL`,
  - liczba rekordów z `venue_id IS NULL`.
- [x] S0.4 Zamrozić kontrakt docelowy `form_id`:
  - `food_cooling`,
  - `meat_roasting`,
  - `delivery_control`.

### Kryteria akceptacji
- [x] Jest raport baseline i zatwierdzony kontrakt `form_id`.

### Artefakty
- `baseline_schema.sql`
- `baseline_haccp_logs_report.md`

---

## Sprint 1: Ujednolicenie `form_id` w aplikacji (1 dzień)

### Cel
Usunąć niespójność zapisu/odczytu w GMP history.

### Zadania
- [x] S1.1 Ujednolicić `formId` w ekranach:
  - roasting -> `meat_roasting`,
  - delivery -> `delivery_control`.
- [x] S1.2 W historii GMP dodać kompatybilny odczyt legacy:
  - `meat_roasting_daily` -> `meat_roasting`,
  - `delivery_control_daily` -> `delivery_control`.
- [x] S1.3 Ujednolicić nazwy procesów i filtry UI.
- [x] S1.4 Dodać test spójności kontraktu `form_id` (UI vs repo/history).

### Kryteria akceptacji
- [x] Nowe wpisy pojawiają się poprawnie w historii dla 3 procesów.
- [x] Legacy wpisy `_daily` pozostają widoczne.

### Ryzyka
- Częściowa migracja może ukryć część historycznych rekordów.

### Wyjście sprintu
- Stabilny kontrakt form w kodzie aplikacji.
