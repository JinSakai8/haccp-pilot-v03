# Sprint 3 PDF Layout (CCP-1)

Data wykonania: 2026-02-22

## 1) Wejscie metody

Nowa metoda:
- `PdfService.generateCcp1TemperatureReport(...)`

Parametry:
- `sensorName`
- `userName`
- `monthLabel`
- `rows` (gotowe wiersze CCP-1 ze Sprintu 2)

## 2) Struktura dokumentu

Implementacja:
- `lib/core/services/pdf_service.dart`

Sekcje:
1. Naglowek staly (3 kolumny):
   - dane lokalu
   - tytul: `Arkusz monitorowania CCP-1`
   - odpowiedzialny
2. Sekcja parametrow:
   - urzadzenie/sensor
   - okres
   - kryterium zgodnosci (`0.0..4.0 C`)
3. Tabela CCP-1 (6 kolumn):
   - Data
   - Godzina
   - Wartosc temperatury
   - Zgodnosc z ustaleniami
   - Dzialania korygujace
   - Podpis
4. Stopka:
   - `Sprawdzil/zatwierdzil...`
   - `(Data/podpis)`

## 3) Wielostronicowosc i brak overlapu

Technika:
- `PdfLayoutFormat(layoutType: PdfLayoutType.paginate)`
- `dataGrid.repeatHeader = true`
- stopka jako `document.template.bottom` (stala na kazdej stronie)

Efekt:
- tabela paginuje sie poprawnie na kolejne strony,
- header tabeli jest powtarzany,
- stopka nie nachodzi na tabele.

## 4) Integracja z M06

Provider:
- `lib/features/m06_reports/providers/reports_provider.dart`

Zmiana:
- sciezka `reportType == 'temperature'` wywoluje
  `generateCcp1TemperatureReport(...)`,
- brak fallbacku do HTML.

## 5) Dowod testowy

Testy:
- `test/pdf_service_test.dart`

Wynik:
- smoke CCP-1: PASS
- multipage CCP-1: PASS (`doc.pages.count > 1`, ekstrakcja tekstu zawiera naglowki i stopke)

