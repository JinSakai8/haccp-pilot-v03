# Context And Decisions (M06 CCP-1 PDF)

## Cel
Przekazac juniorowi jednoznaczny kontekst architektoniczny i zamrozone decyzje przed implementacja.

## Kontekst aktualny
- Obecnie raport `temperature` w M06 jest generowany jako HTML i zwracany jako `.html`.
- W systemie istnieje silnik PDF (`PdfService`) oraz wzorzec arkusza CCP (`CCP-3`), ktory mozna wykorzystac architektonicznie.
- Archiwum raportow opiera sie o:
  - storage bucket `reports`
  - tabele `generated_reports`

## Decyzje zamrozone
1. Typ raportu: `ccp1_temperature`.
2. Zakres raportu: 1 miesiac / 1 sensor.
3. Zgodnosc:
   - `TAK` gdy temperatura w `0..4°C`
   - `NIE` gdy `<0°C` lub `>4°C`
4. Naglowek PDF: staly zgodny z template CSV.
5. `Dzialania korygujace` i `Podpis`: puste.
6. `generation_date`: data generacji.

## Co jest poza zakresem
- Zmiany RLS poza check constraint `report_type`.
- Nowe tabele/kolumny DB.
- Automatyczne uzupelnianie podpisu i dzialan korygujacych.

## Definicja gotowosci do Sprintu 0
- Junior rozumie wszystkie decyzje i nie zmienia kontraktu bez decyzji architekta.

