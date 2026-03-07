# Sprint 5: Testy end-to-end, QA i release

## Cel
Potwierdzic stabilnosc, jakosc i gotowosc do wdrozenia.

## Zakres testow
- [x] Unit:
  - mapowanie zgodnosci (`TAK/NIE`)
  - format daty/godziny
  - nazwa pliku PDF
- [x] Repository:
  - zakres dat miesiaca
  - filtr po 1 sensorze
  - sort po `recorded_at`
- [x] Provider/Widget:
  - walidacja wyboru sensora
  - poprawny komunikat dla no-data
  - poprawna obsluga bledu generacji/uploadu
- [x] Manual QA:
  - pusty miesiac
  - wartosci skrajne temperatur
  - duzy wolumen (wielostronicowosc)
  - wpis w archiwum + pobranie pliku

## Plan release
1. Canary:
   - wdrozenie dla 1 lokalu.
2. Monitoring 48h:
   - bledy generacji PDF
   - bledy uploadu do storage
   - bledy insertu `generated_reports`
3. Pelne wdrozenie:
   - po pozytywnym wyniku canary i braku krytycznych alertow.

## Rollback
- [x] Cofniecie migracji check constraint (`report_type`).
- [ ] Tymczasowy feature toggle: blokada nowej sciezki `ccp1_temperature`.
- [x] Powrot do poprzedniej stabilnej wersji aplikacji, jesli wymagane.

## Kryteria akceptacji (AC)
- [x] Brak regresji na pozostalych typach raportow.
- [x] Raport temperatur dziala stabilnie jako PDF.
- [x] Archiwizacja jest spojna i przewidywalna.

## Artefakty
- Raport Sprint 5:
  - `directives/19_M06_CCP1_PDF_Implementation_Plan/12_Sprint_5_QA_Release_Report.md`

## Status operacyjny
- Technicznie: gotowe do canary.
- Operacyjnie: canary + monitoring 48h do wykonania na produkcji.
