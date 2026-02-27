# Sprint 3: Silnik PDF CCP-1

## Cel
Dodac nowa metode generacji PDF z ukladem 1:1 jak template CSV CCP-1.

## Zadania
- [x] Dodac nowa sciezke w `PdfService` dedykowana CCP-1 temperatur.
- [x] Zaimplementowac layout:
  - staly naglowek (jak CSV)
  - sekcja parametrow
  - tabela kolumn CCP-1
  - stopka "Sprawdzil/zatwierdzil..."
- [x] Zapewnic:
  - wielostronicowosc
  - powtarzanie headera tabeli na kolejnych stronach
  - brak nakladania elementow
- [x] Utrzymac kompatybilnosc z obecnym mechanizmem otwierania/podgladu PDF.

## Testy
- [x] Smoke: generacja zwraca poprawne `bytes`.
- [x] Dataset wielostronicowy nie powoduje overlapu.
- [x] Wiersze zawieraja poprawne wartosci kolumn.

## Artefakty
- Dokument techniczny layoutu (krotki opis mapowania sekcji PDF).
- Dowod testu wielostronicowosci (opis + wynik).
- Plik techniczny:
  - `directives/19_M06_CCP1_PDF_Implementation_Plan/11_Sprint_3_PDF_Layout.md`
- Kod:
  - `lib/core/services/pdf_service.dart`
  - `lib/features/m06_reports/providers/reports_provider.dart`
- Testy:
  - `test/pdf_service_test.dart`

## Kryteria akceptacji (AC)
- [x] Metoda PDF dziala dla datasetu Sprint 2.
- [x] Wygenerowany dokument odpowiada strukturze CCP-1.
