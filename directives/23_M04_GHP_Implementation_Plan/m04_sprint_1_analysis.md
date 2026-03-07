# Sprint 1 - Analiza (Pre-Implementation)

## Status Sprintu
- Status: Zakonczony (analiza i zamrozenie decyzji)
- Data zamkniecia: 2026-02-27
- Decyzja: READY FOR SPRINT 2

## Cel Sprintu
Zamknac niejasnosci kontraktowe i architektoniczne przed implementacja M04 GHP + M06 reporting.

## 1. Zakres analizy i zrodla
Przeanalizowano wszystkie pliki wymagane przez plan Sprintu 1:
- Architektura: `directives/00_Architecture_Master_Plan.md`, `Code_description.MD`, `UI_description.md`, `supabase.md`
- Runtime M04: repo/provider/screens GHP
- Runtime M06: repo/provider/screens reports + `lib/core/services/pdf_service.dart`
- Shared forms: `checklist_definitions.dart`, `dynamic_form_provider.dart`

## 2. Checklista analityczna (wynik)
1. Jawne pole daty/godziny wykonania GHP: NIE
- As-Is: zapis idzie przez `created_at` + dynamiczne `data`; brak kanonicznych pol biznesowych wykonania.

2. Raport GHP generowany z panelu raportow: NIE
- As-Is: typ `ghp` jest na liscie wyboru, ale `reports_provider.dart` rzuca blad "Raport GHP jest w trakcie przygotowania".

3. Raport GHP archiwizowany w `generated_reports`: NIE
- As-Is: brak flow upload + metadata dla typu GHP.

4. Widok szczegolow wpisu historii GHP: NIE
- As-Is: lista kart bez nawigacji do szczegolow (komentarz "Details view could be added later").

5. Otwieranie raportow na web/mobile: CZESCIOWO
- As-Is: web dziala (`file_opener_web.dart`), mobile ma stub (`file_opener_stub.dart`) i brak realnego otwierania.

6. Lista chemii jako runtime source (DB/config): NIE
- As-Is: hardcoded mock lista w `ghp_chemicals_screen.dart`.

## 3. Macierz As-Is vs To-Be (M04/M06)
| Obszar | As-Is | To-Be (zamrozone) |
|:--|:--|:--|
| Kontrakt wykonania GHP | `created_at` i dowolne pola w `data` | `data.execution_date` + `data.execution_time` jako pola wymagane dla kazdego zapisu GHP |
| Raport GHP | Brak implementacji w providerze | Miesieczny raport GHP generowany z `haccp_logs(category='ghp')` |
| Archiwum raportow GHP | Brak metadata type | `generated_reports.report_type = 'ghp_checklist_monthly'` + upsert po `(venue_id, report_type, generation_date)` |
| Historia GHP | Lista wpisow bez detalu | Lista + ekran detalu wpisu (payload, wykonawca, data wykonania, created_at) |
| PDF open mobile | Stub | Strategia: otwieranie przez natywny flow mobile (nie stub), parity z web w Sprint 4 |
| Chemia GHP | Hardcoded list | Runtime source z DB/config (bez hardcode w screenie) |

## 4. Zamrozony kontrakt danych
### 4.1 Payload GHP (`haccp_logs`)
- `category`: `ghp`
- `form_id`: `ghp_personnel` | `ghp_rooms` | `ghp_maintenance` | `ghp_chemicals`
- `data` (minimum):
  - `execution_date`: `YYYY-MM-DD` (required)
  - `execution_time`: `HH:mm` (required)
  - `answers`: obiekt odpowiedzi checklisty/chemii (required)
  - `notes`: string (optional)
- `user_id`, `zone_id`, `venue_id`, `created_at`: zgodnie z obecnym kontraktem tabeli

### 4.2 Metadata raportu GHP (`generated_reports`)
- `report_type`: `ghp_checklist_monthly`
- `generation_date`: pierwszy dzien raportowanego miesiaca (`YYYY-MM-01`)
- `storage_path`: `reports/<venueId>/<YYYY>/<MM>/ghp_checklist_<YYYY-MM>.pdf`
- `metadata` (minimum):
  - `period_start`
  - `period_end`
  - `template_version` (start: `ghp_pdf_v1`)
  - `source_form_id` (`ghp_*` lub `ghp_all`)
  - `zone_id` (jezeli raport strefowy)

## 5. Zamrozone decyzje architektoniczne
1. Format pola wykonania: OPCJA A
- Uzywamy `execution_date` + `execution_time` w `data` JSON.
- Powod: czytelny kontrakt biznesowy, prostsze filtrowanie dzienne i zgodnosc z celem master planu.

2. Typ raportu GHP
- Uzywamy `ghp_checklist_monthly`.
- Wymaga rozszerzenia `generated_reports_report_type_check` w migracji Sprintu 2.

3. Filtry historii GHP
- Must-have: `zone_id` (scoping) + zakres dat + kategoria (`form_id`) + wykonawca (`user_id`).
- Sortowanie: malejaco po `data.execution_date + execution_time`, fallback `created_at`.

4. Strategia otwierania PDF na mobile
- Rezygnacja ze stuba; wdrozenie realnego mobile open flow w Sprint 4.
- Wymaganie: brak roznic funkcjonalnych user-facing miedzy web i mobile.

## 6. Ryzyka i priorytety
- P1: Dryf kontraktu wykonania (`execution_*`) miedzy UI/provider/repository/reporting.
- P1: Niezgodnosc constraint `generated_reports.report_type` blokuje archiwizacje GHP.
- P1: Brak mobile PDF open powoduje niespelnienie wymagan cross-target.
- P2: Historia bez detalu utrudnia audyt i diagnostyke operacyjna.
- P2: Hardcoded chemia utrudnia utrzymanie i lokalne konfiguracje lokalu.
- P3: Potencjalna niespojnosc nazewnictwa `gmp_daily` vs nowe nazwy raportow (legacy porzadki).

## 7. Ownerzy i pliki docelowe (Sprint 2+)
| Obszar | Owner | Pliki |
|:--|:--|:--|
| Kontrakt danych GHP + mapowanie payload | M04 | `lib/features/m04_ghp/providers/ghp_provider.dart`, `lib/features/m04_ghp/repositories/ghp_repository.dart` |
| Definicje formularzy GHP (execution fields) | Shared | `lib/features/shared/config/checklist_definitions.dart` |
| Raport GHP generation flow | M06 | `lib/features/m06_reports/providers/reports_provider.dart`, `lib/features/m06_reports/repositories/reports_repository.dart` |
| PDF layout GHP | Core/PDF | `lib/core/services/pdf_service.dart` |
| GHP history detail UI | M04 UI | `lib/features/m04_ghp/screens/ghp_history_screen.dart` (+ nowy detail screen) |
| Archiwum i preview parity web/mobile | M06 UI + Core | `lib/features/m06_reports/screens/saved_reports_screen.dart`, `lib/core/services/file_opener_*` |
| DB constraint/report_type + ewentualne indeksy | Data | `supabase/migrations/*` |
| Runtime source chemii | M04 + Data | `lib/features/m04_ghp/screens/ghp_chemicals_screen.dart` + repo/config source |

## 8. Exit Criteria (weryfikacja)
- Brak otwartych pytan kontraktowych: SPELNIONE.
- Kazda przyszla zmiana ma ownera i plik docelowy: SPELNIONE.
- Sekwencja wdrozeniowa jest jednoznaczna: SPELNIONE.

## 9. Ready for Sprint 2
Sprint 1 zamkniety. Mozna rozpoczac Sprint 2 (Data + Reporting Contract) bez dodatkowych doprecyzowan.
