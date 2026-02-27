# Context And Decisions (M02 Tabela 7D + Edit)

## Cel
Przekazac juniorowi jednolity kontekst architektoniczny i zamrozone decyzje wykonawcze.

## Stan aktualny
- M02 posiada wykres dla zakresow `24h`, `7 dni`, `30 dni`.
- Brakuje widoku tabelarycznego wszystkich pomiarow z 7 dni.
- Edycja temperatury nie istnieje.
- `temperature_logs` ma zbyt liberalny model update (do hardeningu).

## Decyzje zamrozone
1. Tabela 7 dni jest per sensor i otwierana z ekranu wykresu sensora.
2. Edycja to nadpisanie `temperature_celsius`.
3. Edycja tylko dla roli `manager` / `owner`.
4. Edytujemy tylko temperature (bez zmiany czasu i sensora).
5. Limit czasu edycji: `recorded_at >= now() - interval '7 days'`.
6. Backend wymusza reguly przez RPC i RLS, nie tylko przez UI.

## Poza zakresem
- Pe³na historia wersji pomiaru w osobnej tabeli.
- Edycja `recorded_at` lub `sensor_id`.
- Przebudowa pozostalych modulow poza koniecznymi touchpointami M02.
