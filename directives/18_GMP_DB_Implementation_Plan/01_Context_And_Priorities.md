# Context And Priorities (na bazie `supabase.md`)

## Cel
Ustabilizować przepływ danych GMP (w tym chłodzenie) oraz raportów CCP-3 na tabeli `haccp_logs`, z poprawną izolacją danych (`zone_id`, `venue_id`) i kontrolą RLS.

## Kontekst bazy (źródło: `supabase.md`)
- Główna tabela procesu GMP/GHP: `haccp_logs`.
- Kluczowe kolumny: `category`, `form_id`, `data`, `zone_id`, `venue_id`, `user_id`, `created_at`.
- M03 GMP zapisuje/odczytuje `haccp_logs`; M06 Reports czyta `haccp_logs` i zapisuje `generated_reports`.
- W fazie pilotowej opisane są uproszczone polityki RLS (`USING (true)` / `CHECK (true)`), co zwiększa ryzyko mieszania danych bez filtrów aplikacyjnych.

## Główne problemy do usunięcia
1. Niespójność `form_id` między ekranami zapisu i historią.
2. CCP-3 bez pełnego filtrowania kontekstu (strefa/lokal).
3. Zbyt liberalne RLS dla `haccp_logs` w trybie pilotowym.
4. Potrzeba migracji danych historycznych po normalizacji kontraktu.

## Priorytety wdrożenia
1. Stabilizacja kontraktu danych (`form_id`) + kompatybilność wsteczna.
2. Naprawa odczytu CCP-3 (`zone_id`/`venue_id`).
3. Hardenowanie DB (RLS, indeksy, constraints).
4. Migracja danych historycznych.
5. Testy E2E i rollout kontrolowany.

## Definicja sukcesu
- Brak przypadków „zapisano, ale nie ma w historii”.
- Brak przypadków „CCP-3 pokazuje dane z innej strefy/lokalu”.
- Stabilny zapis GMP po wdrożeniu (błędy <1% / 7 dni).
