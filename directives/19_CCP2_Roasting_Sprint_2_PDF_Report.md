# Sprint 2: PDF Raporty (Moduł M06)

**Cel Sprintu:** Implementacja raportu tabelarycznego PDF na bazie logów z ekranów Pieczenia Mięs zgodnie z architekturą raportową w M06 i Syncfusion Flutter PDF.

## Działania: Logika Pobierania (Provider/Repo)

- Utrzymanie/rozbudowa zapytań w warstwie backendowej repozytorium raportów (np. `ReportsRepository`), by do metody generacji raportu wczytać odfiltrowane dane dla `haccp_logs` w danym miesiącu roku (filtr `venue_id = context`,  `form_id = 'meat_roasting'`).
- Mapowanie do lokalnego DTO weksportowanego przez JSON (`parsedData`), tak by móc sciągnać stempel czasu, `is_compliant`, i podpis `user_id` -> Employee Name/Role z `created_by`.

## Działania: Skrypt SQL Migracji (Supabase)

- Dla tabeli `generated_reports`, typy kolumny rozróżniane są poprzez klauzulę Constraint Check. Utworzyć nową migrację SQL polegającą na usunięciu starego i utworzeniu nowego checka tak, by dopuścił element `ccp2_roasting` do zapisania struktury dla tabel PDF w bazie.

    ```sql
    ALTER TABLE public.generated_reports DROP CONSTRAINT IF EXISTS generated_reports_report_type_check;
    ALTER TABLE public.generated_reports ADD CONSTRAINT generated_reports_report_type_check CHECK (report_type IN ('ccp3_cooling', 'waste_monthly', 'gmp_daily', 'ccp1_temperature', 'ccp2_roasting'));
    ```

## Działania: Generowanie PDF

- Plik: Katalog serwisowy (np. `Ccp2PdfGenerator` lub funkcja generatora wewnątrz `PdfService` podobnie jak do innych), celem stworzenia pliku wg wzorów widokowych w projekcie "Arkusz Monitorowania CCP-2".
- Nagłówek i parametry:
  - Arkusz monitorowania CCP - 2 (jako H1 / Bold Title)
  - Nazwa lokalu (odczytywana z globalnego providera Settings z DB `venues`)
  - Wartość docelowa temperatury > 90°C (Druk u góry formularza)
  - Upoważniony pracownik (Odpowiedzialny)
- Tworzenie siatki dla tabeli z elementami:
  1. Data
  2. Rodzaj potrawy
  3. Wartość temperatury
  4. Zgodność z ustaleniami
  5. Działania korygujące
  6. Podpis
