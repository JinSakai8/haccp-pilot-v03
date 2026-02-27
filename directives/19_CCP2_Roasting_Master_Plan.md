# Master Plan: Wdrożenie Arkusza Monitorowania CCP-2 (Pieczenie Mięs)

> **Autor:** Lead System Architect (AI)
> **Data:** Luty 2026
> **Cel:** Zaprojektowanie i wdrożenie funkcjonalności generowania i raportowania danych z procesu GMP "Pieczenie Mięs" na wzór układu "Arkusz monitorowania CCP-2", z pełną analogią do procesu CCP-3 (Chłodzenie).

Wprowadzane zmiany będą głównie oparte o istniejące układy formularzy `M03 GMP` oraz parser PDF z `M06 Reports`.

## Przegląd Wymagań (na podstawie dostarczonego wzoru)

1. **Wartość docelowa i tolerancja:**
   - Wartość docelowa: >90°C
   - Tolerancja: Bez tolerancji (Krytyczna: 90°C)
2. **Układ Kolumn Raportu (PDF/Tabela):**
   - Data
   - Rodzaj potrawy
   - Wartość temperatury (°C)
   - Zgodność z ustaleniami (TAK/NIE)
   - Działania korygujące
   - Podpis (Osoba autoryzowana)

## Ogólna Architektura Rozwiązania

Formularz Pieczenia Mięs (dostępny pod `meat_roasting_form_screen.dart`) należy rozszerzyć o dodatkową informację o "Zgodności z ustaleniami" (za pomocą `HaccpToggle`) oraz "Działaniach korygujących" (za pomocą elementu wejściowego TextField, pokazującego się wtedy kiedy użytkownik przełączy przycisk statusu problemu - analogicznie do CCP-3 Chłodzenie).
Parametry te trafią w ładunku JSONB do struktury tabeli bazy danych `haccp_logs` z polem odpowiadającym `form_id = 'meat_roasting'`.

Wyodrębniony zostanie nowy model raportu w module `M06 Reports`, który poprzez agregat pobierze historyczne logi z `haccp_logs` za określony miesiąc (dla aktywnego `venue`). Generacja oparta zostanie na wtyczce Syncfusion PDF z dynamicznym mapowaniem do PDF, i na końcu podlinkowana na podgląd. Nowy PDF zapisywany będzie w tabeli `generated_reports` bazy danych pod nowym `report_type = 'ccp2_roasting'`.

## Podział Zadań na Sprinty Mniejsze

- **Sprint 1 (Formularze & DB):** Dostosowanie UI w `M03`, rozszerzenie payloadu w `haccp_logs` oraz poprawa walidacji progowej na min 90°C wewnątrz `meat_roasting_form_screen.dart`. Zobacz: `19_CCP2_Roasting_Sprint_1_Form_DB.md`
- **Sprint 2 (Generowanie PDF Raportów M06):** Utworzenie backendowych komponentów dla Fluttera, mapowanie z modelem DB `haccp_logs` dla form `meat_roasting`, zrzut kolumn dla specyfikacji CCP-2 w PDF. Dodanie wpisu CHECK constraint do DB. Zobacz: `19_CCP2_Roasting_Sprint_2_PDF_Report.md`
- **Sprint 3 (Integracja & Odbiór UX/QA):** Dodanie interfejsów wywoławczych wygenerowania raportów CCP-2 do panelu Raportów (Ekran 6.1) tak, by obsłużyć jego wybór obok wdrożonego wcześniej CCP-3. Zobacz: `19_CCP2_Roasting_Sprint_3_Tests_Verification.md`
