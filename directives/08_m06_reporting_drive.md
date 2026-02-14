# Directive 08: Module M06 - PDF Generation & Google Drive Automation

## Cel
Implementacja automatycznego generowania raportów PDF i ich bezpiecznego przesyłania do chmury Google Drive.

## Zadania (Execution)
1. **Dependencies:** Dodaj `syncfusion_flutter_pdf`, `googleapis`, `googleapis_auth` do `pubspec.yaml`.
2. **Drive Service:**
   - Zaimplementuj `DriveService` korzystając z `credentials.json`.
   - Dodaj metodę `uploadReport(File file, String folderId)`.
3. **PDF Engine:**
   - Zaimplementuj `PdfService`. 
   - Musi on mapować dane z `gmp_logs`, `ghp_logs` oraz `waste_records` na format tabelaryczny.
   - Uwzględnij zdjęcia: Pobierz zdjęcia z Supabase Storage i umieść je w załączniku PDF (skaluj do szerokości strony).
4. **UI Integration:**
   - Ekran `ReportsPanelScreen` z prostym wyborem daty i przyciskiem "Generuj i Wyślij".
   - Loader (CircularProgressIndicator) z informacją: "Generowanie dokumentu...", "Przesyłanie do chmury...".

## Rygor
- Użyj `compute()` (Isolates) dla operacji generowania PDF.
- Ścieżka do folderu Drive ma być pobierana z pliku `.env` jako `GOOGLE_DRIVE_FOLDER_ID`.