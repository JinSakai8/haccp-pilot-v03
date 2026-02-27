# Sprint 3: Integracja Ekranów M06, Testy i Odbiór UX

**Cel Sprintu:** Zintegrowanie nowego raportu M06 CCP-2 Pieczenie Mięs z głównym panelem Raportów w aplikacji, testowanie regresji oraz przetestowanie generacji na produktywnych strukturach bazy danych.

## Działania: UI (Integracja)

- Plik: `lib/features/m06_reports/screens/reports_panel_screen.dart`
- Dodać wejście/przycisk dla `CCP-2 Pieczenie Mięs` obok `CCP-3 Chłodzenie`.
- Wywołanie modalnego wyboru miesiąca.
- Pobieranie danych i przekierowanie do wygenerowanego ekranu podglądu PDF `PdfPreviewScreen` (gdzie plik załaduje podgląd `Ccp2PdfGenerator`).
- Sprawdzić zapisywanie poprawności pliku w Supabase Storage `reports/{venueId}/{YYYY}/{MM}/ccp2_roasting_{YYYY-MM}.pdf`.

## Działania: Testy (Dart/Flutter Test)

- **Test Jednostkowy Formularza Pieczenia:**
  - Plik do sprawdzenia: `test/features/m03_gmp/meat_roasting_form_test.dart`
  - Utworzyć/uaktualnić test sprawdzający, że gdy temperatura wejściowa wynosi 80°C, to pokazuje się pole ostrzeżenia o zbyt małej temperaturze docelowej (weryfikacja zmiany wymogu z 75 na 90).
  - Test sprawdzający obecność pola komentarza "Działania korygujące" w strukturze po przełączeniu opcji "Zgodność z ustaleniami" na falsh.
- **Test Generacji PDF:**
  - Plik: `test/features/m06_reports/ccp2_pdf_gen_test.dart`
  - Test sprawdza, czy model poprawnie odbiera z backendu pola `is_compliant` oraz `corrective_actions` uwzględniając wsteczną kompatybilność, z wczesnymi wpisami bez tego pola (null = false/empty).
  - Weryfikacja formatki wywołania z odpowiednimi limitami nagłówka "Arkusz monitorowania CCP-2".
- **Smoke test środowiskowy:**
  - Utworzenie skryptu SQL do walidacji logi BD `haccp_logs` z typem `form_id = 'meat_roasting'` z dopisaniem `is_compliant` i aktualizacji check-constraint `generated_reports`.

## Odbiór UX i Checklist

- Upewnić się, że zmiana walidacji temperatury nie zablokowała możliwości zapisu (wytyczne projektowe HACCP Pilot v03 wymagają, aby ostrzeżenie nie blokowało zapisu long press).
- W panelu historii GMP sprawdzić podgląd ikonek OK / Ostrzeżenie na nowym zestawie parametrów.
