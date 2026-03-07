# Sprint 0: Baseline i Audyt Stanu

Data baseline: 2026-02-26  
Status: IN PROGRESS (artefakty bazowe gotowe)

## Cel sprintu
Zebraæ twarde dane o aktualnym dzia³aniu CCP2 i CCP3 przed dalszym wdra¿aniem unifikacji.

## Zakres wykonany
1. Audyt flow w kodzie:
- M03 historia -> preview CCP2/CCP3.
- M06 preview -> storage -> `generated_reports`.
- M06 archiwum -> reopen/fallback regeneracji.
2. Matryca stanu funkcjonalnego CCP2/CCP3.
3. Snapshot testów bazowych M03/M06.
4. Przygotowanie zapytañ SQL do snapshotu DB (`generated_reports`, `haccp_logs`).

## Mapa flow (stan aktualny)
1. `M03 > GMP Historia`
- `gmp_history_screen.dart`: klik dla `food_cooling` prowadzi do `/reports/preview/ccp3?date=YYYY-MM-DD`.
- `gmp_history_screen.dart`: klik dla `meat_roasting` prowadzi do `/reports/preview/ccp2?date=YYYY-MM-DD`.
2. `M06 > Preview`
- `ccp2_preview_screen.dart` i `ccp3_preview_screen.dart` pracuj¹ na okresie miesiêcznym (`monthStart/monthEnd`).
- Najpierw lookup cache w `generated_reports` po `venue_id + report_type + generation_date`.
- Gdy brak lub uszkodzony PDF: regeneracja i ponowny zapis.
3. `Storage + metadata`
- Upload do bucketu `reports` ze œcie¿k¹ `{venueId}/{YYYY}/{MM}/{file}.pdf`.
- Upsert w `generated_reports` przez `onConflict: venue_id,report_type,generation_date`.
4. `M06 > Archiwum`
- `saved_reports_screen.dart` pobiera raporty per aktywny `venue_id`.
- Dla uszkodzonego CCP2/CCP3 uruchamia `force=1` i przechodzi do preview regeneruj¹cego.

## Matryca stanu (CCP2 vs CCP3)
| Obszar | CCP2 | CCP3 | Uwagi |
|---|---|---|---|
| M03 Historia -> Preview | DZIA£A | DZIA£A | Routing podpiêty po normalizacji `form_id`. |
| M06 Panel raportów (wybór typu+miesi¹ca) | DZIA£A | DZIA£A | Oba typy dostêpne i kieruj¹ do preview. |
| Semantyka okresu | MIESI¥C | MIESI¥C | Oba preview licz¹ zakres `1..koniec miesi¹ca`. |
| Cache lookup (`generated_reports`) | DZIA£A | DZIA£A | Scope zawê¿ony do `venue_id`. |
| Archiwum reopen | DZIA£A | DZIA£A | Fallback regeneracji w przypadku uszkodzonego PDF. |
| Metadata kontraktowa | DZIA£A | DZIA£A | `period_start`, `period_end`, `template_version`, `source_form_id`. |

## Problemy/rozjazdy wykryte w baseline
1. Niespójnoœæ `storage_path`:
- Czêœæ flow zapisuje `storage_path` jako œcie¿kê bez prefiksu `reports/`, czêœæ z prefiksem.
- Repo ma normalizacjê przy pobieraniu, wiêc runtime dzia³a, ale kontrakt DB jest niejednorodny.
2. Brak twardego snapshotu liczników DB w tym dokumencie:
- Przygotowano gotowe SQL, ale liczby runtime wymagaj¹ wykonania na aktywnym œrodowisku.
3. Cache key w providerach preview uwzglêdnia dzieñ (`date.day`) mimo miesiêcznej semantyki:
- Nie ³amie poprawnoœci danych, ale mo¿e powodowaæ niepotrzebne rozró¿nienie requestów.

## Snapshot testów (baseline)
1. `C:\scr\flutter\bin\flutter.bat test test/features/m03_gmp --reporter compact`
- Wynik: PASS (`8 passed, 0 failed`).
2. `C:\scr\flutter\bin\flutter.bat test test/features/m06_reports --reporter compact`
- Wynik: PASS (`27 passed, 0 failed`).

## Ryzyka i priorytety
1. P1: Niejednolity format `storage_path` w `generated_reports`.
2. P1: Brak potwierdzonego snapshotu count/sample z produkcyjnej DB dla `ccp2_roasting` i `ccp3_cooling`.
3. P2: Drobna niespójnoœæ cache key (dzieñ vs miesi¹c) w request DTO preview.

## Artefakty Sprint 0
1. Ten dokument: baseline i matryca stanu.
2. `22_Sprint_0_Manual_Checklist.md`: checklista scenariuszy manualnych.
3. `22_Sprint_0_DB_Snapshot_Queries.sql`: zapytania count/sample i walidacje rozjazdów.

## Exit criteria (na teraz)
1. Baseline architektury aplikacyjnej: SPE£NIONE.
2. Baseline testów M03/M06: SPE£NIONE.
3. Baseline DB count/sample na œrodowisku docelowym: DO WYKONANIA (SQL gotowe).
