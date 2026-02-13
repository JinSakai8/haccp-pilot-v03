# **Raport Wdrożeniowy: Kompleksowa Architektura i Plan Implementacji Systemu HACCP Pilot w Ekosystemie Google Antigravity**

## **1\. Wstęp: Paradygmat "Agent-First" w Inżynierii Systemów Gastronomicznych**

Współczesna inżynieria oprogramowania przechodzi fundamentalną transformację, odchodząc od ręcznego kodowania (manual coding) na rzecz orkiestracji systemów autonomicznych. W kontekście projektu "HACCP Pilot" – zaawansowanego systemu ERP dla gastronomii – kluczowym wyzwaniem nie jest jedynie implementacja funkcjonalności, lecz stworzenie skalowalnej architektury, która sprosta rygorystycznym wymaganiom sanitarnym (Sanepid), środowiskowym (BDO) oraz operacyjnym (praca w trudnych warunkach kuchennych). Niniejszy raport stanowi wyczerpującą mapę drogową, zaprojektowaną specyficznie dla środowiska Google Antigravity, wykorzystującą najnowsze modele sztucznej inteligencji do generowania kodu, testowania i wdrożenia aplikacji.1

Zgodnie z najnowszą specyfikacją (wersja 03-00), system ewoluował z modelu Offline-First w stronę architektury **Online-First**, gdzie centralnym źródłem prawdy jest chmurowa baza danych Supabase.3 Ta zmiana paradygmatu wymusza zastosowanie nowoczesnych technik inżynieryjnych, takich jak Webhooki do obsługi IoT, Edge Functions do logiki biznesowej oraz natywną integrację z Google Drive API do archiwizacji dokumentacji. Wykorzystanie środowiska Antigravity pozwala na podzielenie procesu deweloperskiego na dwie fazy: planowania strategicznego (realizowanego przez model "Seniora" – Claude 3.5 Sonnet lub Gemini 3.0 Pro w trybie Planning) oraz egzekucji taktycznej (realizowanej przez model "Juniora" w trybie Fast/Execution).1

Poniższy dokument przeprowadza architekta systemu przez każdy etap procesu, dostarczając gotowe, inżynieryjne prompty, struktury plików oraz strategie weryfikacji jakości, niezbędne do stworzenia aplikacji klasy Enterprise przy minimalnym nakładzie pracy manualnej.

## ---

**2\. Przygotowanie Środowiska Operacyjnego: Protocol Zero**

### **2.1. Konfiguracja IDE i Wybór Modeli**

Środowisko Google Antigravity funkcjonuje jako zaawansowane IDE, które integruje lokalny system plików z mocą obliczeniową chmury. Aby zapewnić płynność pracy nad projektem o tak wysokim stopniu złożoności jak HACCP Pilot, konieczna jest precyzyjna konfiguracja narzędzi. Zgodnie z analizą wydajności modeli, rekomenduje się hybrydowe podejście do wyboru silnika AI:

* **Claude 3.5 Sonnet:** Model ten wykazuje wyższą skuteczność w generowaniu złożonej logiki backendowej, schematów SQL oraz architektury systemowej. Będzie pełnił rolę "Senior Architekta".2  
* **Gemini 3.0 Pro:** Ze względu na multimodalność i szybkość, model ten idealnie sprawdza się w generowaniu interfejsu użytkownika (Flutter UI), pracy z kontekstem wizualnym (rozpoznawanie schematów ze zdjęć) oraz w trybie szybkiej iteracji ("Junior Developer").1

Tabela 1\. Strategia wykorzystania trybów pracy w Google Antigravity dla projektu HACCP Pilot

| Tryb Pracy (Mode) | Rola w Projekcie | Zastosowanie Operacyjne | Rekomendowany Model |
| :---- | :---- | :---- | :---- |
| **Planning Mode** | Senior Architect | Analiza wymagań, projektowanie schematu bazy danych Supabase, definicja API kontraktów, planowanie algorytmu IoT 10/5/3. | Claude 3.5 Sonnet |
| **Fast Mode** | Junior Developer | Generowanie widoków Flutter (UI), stylowanie komponentów, drobne poprawki (Hotfixes), implementacja prostych funkcji CRUD. | Gemini 3.0 Pro |
| **Audit Mode** | The Nerd (QA) | Weryfikacja bezpieczeństwa (RLS), audyt zgodności z "Glove-Friendly UX", testy integracyjne. | Claude 3.5 Sonnet |

### **2.2. Konstytucja Projektu: Plik Gemini.MD**

Fundamentem pracy w Antigravity jest stworzenie pliku "konstytucyjnego", który definiuje zasady, ograniczenia i kontekst dla wszystkich agentów AI pracujących nad projektem. Plik ten, nazwany Gemini.MD (lub .agent/rules/project\_rules.md), jest wczytywany przy każdym zadaniu, zapobiegając "dryfowaniu" projektu i halucynacjom modeli.1

**Krok Operacyjny:** W głównym katalogu projektu utwórz plik Gemini.MD i wprowadź do niego poniższą treść, która syntetyzuje wymagania ze specyfikacji 03-00 oraz najlepsze praktyki inżynieryjne.

# **HACCP Pilot \- Project Constitution (Protocol Zero)**

## **1\. North Star (Cel Nadrzędny)**

Stworzenie niezawodnego systemu klasy ERP dla gastronomii (HACCP Pilot v03-00), który automatyzuje monitoring bezpieczeństwa żywności, minimalizując obciążenie personelu. System musi być "Sanepid-Ready" i zgodny z polskimi regulacjami BDO.

## **2\. Architecture & Tech Stack**

* **Architecture:** Online-First. Supabase jako "Single Source of Truth".  
* **Frontend:** Flutter (Dart). Kod musi być czysty, modularny, z wykorzystaniem flutter\_riverpod do zarządzania stanem.  
* **Backend:** Supabase (PostgreSQL, Auth, Edge Functions, Realtime).  
* **IoT:** Integracja z Efento Cloud via Webhooki. Protokół CoAP/NB-IoT.  
* **Storage:** Supabase Storage (zdjęcia odpadów) \+ Google Drive API (archiwum raportów PDF).

## **3\. Critical Rules (Nienaruszalne Zasady)**

* **Glove-Friendly UX:** Wszystkie elementy interaktywne muszą mieć min. 48x48dp. UI musi być obsługiwane w rękawiczkach (duży kontrast, brak precyzyjnych gestów).3  
* **Kiosk Mode:** Aplikacja działa w trybie "App Pinning". Blokada wyjścia do systemu Android.3  
* **Data Integrity:** Brak możliwości edycji surowych danych z sensorów. Adnotacje są dozwolone tylko jako osobna warstwa danych.3  
* **Safety Override:** Algorytm 10/5/3 musi działać po stronie backendu (Edge Function), aby zagwarantować alarmy niezależnie od stanu tabletu.3

## **4\. Coding Standards**

* Stosuj typowanie ścisłe (Strong Typing).  
* Każdy plik musi zawierać nagłówek z opisem odpowiedzialności.  
* Używaj uuid jako kluczy głównych w bazie danych.  
* Logika biznesowa (np. generowanie PDF) musi być odseparowana od warstwy prezentacji.

## ---

**3\. Architektura Danych: Supabase SQL (Senior Architect)**

Pierwszym etapem implementacji jest stworzenie solidnego fundamentu danych. Wykorzystamy tryb **Planning Mode** z modelem Claude 3.5 Sonnet, aby wygenerować kompletny schemat SQL, uwzględniający relacje, typy danych oraz polityki bezpieczeństwa (RLS). Zgodnie ze specyfikacją, system musi obsługiwać złożoną strukturę organizacyjną (Firma \-\> Lokal \-\> Strefa) oraz specyficzne logi procesowe.3

### **3.1. Prompt Inicjalizujący Bazę Danych**

Wpisz poniższy prompt w oknie czatu Antigravity, upewniając się, że aktywny jest tryb Planning.

**Prompt dla Senior Architekta:**

"Jako Senior Database Architect, przygotuj kompletny, wykonywalny skrypt migracji SQL dla bazy Supabase (PostgreSQL), realizujący wymagania systemu HACCP Pilot v03-00. Przeanalizuj plik Gemini.MD i stwórz następującą strukturę tabel, uwzględniając relacje (Foreign Keys), indeksy dla wydajności oraz polityki Row Level Security (RLS) dla izolacji danych między lokalami:

1. **profiles (M01/M07):** Rozszerz tabelę auth.users. Pola: id (FK do auth.users), pin\_code (hashowany \- do szybkiego logowania), role (enum: worker, manager, owner), venue\_id, sanepid\_checkup\_expiry (Date), notification\_status (JSONB \- flagi powiadomień 30/14/7 dni). *Wymóg:* System nie blokuje logowania po wygaśnięciu badań, tylko monitoruje status.3  
2. **venues (M01):** Struktura lokalu. Pola: id (UUID), company\_id, name, google\_drive\_folder\_id (kluczowe dla modułu M06 \- archiwizacja raportów), settings (JSONB \- konfiguracja lokalu).  
3. **zones (M01):** Strefy fizyczne (np. Chłodnia, Kuchnia). Pola: id, venue\_id, name, sensor\_mapping\_id (powiązanie z Efento).  
4. **measurements (M02):** Pomiary IoT. Pola: id, sensor\_id, temperature\_value (Numeric), timestamp (TIMESTAMPTZ \- krytyczne dla synchronizacji), interval\_mode (Enum: standard\_15, alert\_5), alarm\_status (Boolean), annotations (Text \- np. 'Dostawa'). *Logika:* Pole interval\_mode musi wspierać algorytm 10/5/3.3  
5. **gmp\_logs (M03):** Procesy produkcyjne. Pola: id, process\_type (roasting, cooling, delivery), data (JSONB \- przechowuje krzywe chłodzenia, temperatury pieczenia), pest\_check (Boolean \- obowiązkowe przy dostawie), user\_id, created\_at.  
6. **ghp\_logs (M04):** Checklisty higieny. Pola: id, checklist\_type (personnel, premises, equipment), entries (JSONB \- stan checkboxów), is\_compliant (Boolean), manager\_signature\_url.  
7. **waste\_records (M05):** BDO. Pola: id, waste\_code (np. '20 01 25'), weight, certificate\_photo\_url (Link do Supabase Storage), created\_at.

**Instrukcje dodatkowe:**

* Skonfiguruj RLS tak, aby użytkownik widział tylko dane ze swojego venue\_id.  
* Dodaj triggery updated\_at.  
* Wygeneruj kod SQL gotowy do uruchomienia w SQL Editorze Supabase."

### **3.2. Weryfikacja i Egzekucja**

Po otrzymaniu planu i kodu SQL od agenta:

1. Skopiuj kod SQL.  
2. Wklej go do edytora SQL w panelu Supabase i uruchom.  
3. Sprawdź, czy tabela measurements posiada pole interval\_mode – jest to fundament algorytmu inteligentnego monitoringu.3

## ---

**4\. Moduł M01: Rdzeń Aplikacji i Interfejs "Glove-Friendly"**

Interfejs użytkownika jest krytycznym elementem systemu, który musi być obsługiwany w trudnych warunkach (mokre ręce, rękawiczki). Wykorzystamy **Fast Mode** i model Gemini 3.0 Pro, który doskonale radzi sobie z generowaniem kodu wizualnego Fluttera.2

### **4.1. Generowanie Systemu Designu**

**Prompt dla Junior Developera (Fast Mode):**

"Jako Senior Flutter Developer, stwórz plik app\_theme.dart definiujący system designu zgodny z zasadą 'Glove-Friendly UX'.

**Wymagania wizualne:**

1. Minimalny rozmiar elementów dotykowych (Touch Target) musi wynosić 60x60 logicznych pikseli.3  
2. Kolorystyka sygnalizacyjna o wysokim kontraście: OK \= \#2E7D32 (Ciemna Zieleń), Alarm/Błąd \= \#C62828 (Ciemna Czerwień), Tło \= \#FFFFFF.  
3. Typography: Użyj fontu sans-serif (np. Roboto), minimalny rozmiar tekstu głównego 18sp.  
4. Zdefiniuj style przycisków ElevatedButton z domyślnym paddingiem 16dp.

Wygeneruj kod Dart."

### **4.2. Implementacja Ekranu Logowania (Kiosk Mode)**

Logowanie musi być szybkie i bezpieczne.

**Prompt dla Junior Developera:**

"Stwórz ekran LoginScreen w Flutterze obsługujący logowanie kodem PIN.

**Specyfikacja:**

1. Ekran ma działać w trybie pełnoekranowym (Kiosk).  
2. Centralnym elementem jest duży PIN Pad (siatka 3x4 przycisków numerycznych 0-9, Kasuj, Zaloguj).  
3. Przyciski numeryczne muszą być ogromne (np. 80x80dp), łatwe do trafienia w rękawiczkach.  
4. Logika: Po wpisaniu 4-6 cyfr, wywołaj funkcję AuthService.verifyPin(pin).  
5. Dodaj obsługę błędów: Wyświetl duży, czerwony komunikat 'Błędny PIN' przez 2 sekundy, a następnie wyczyść pole.  
6. Obsłuż 'App Pinning' – przy starcie aplikacji wywołaj natywną metodę Androida startLockTask() (użyj kanałów platformowych). Napisz także kod po stronie Androida (Kotlin) w MainActivity.kt obsługujący to wywołanie.3"

## ---

**5\. Moduł M02: Backend IoT i Algorytm 10/5/3**

To "mózg" systemu, który musi działać niezawodnie, nawet gdy tablet jest wyłączony. Dlatego logika zostanie zaimplementowana jako Supabase Edge Function (TypeScript/Deno), wyzwalana przez webhooki z Efento Cloud.3

### **5.1. Architektura Edge Function**

**Prompt dla Senior Architekta (Planning Mode):**

"Zaprojektuj i napisz kod dla Supabase Edge Function o nazwie process-sensor-reading. Funkcja ta będzie punktem końcowym (Webhookiem) dla danych z Efento Cloud.

**Logika Algorytmu 10/5/3 (Specyfikacja v03-00):**

1. Odbierz payload JSON z sensora (zawiera sensor\_id, temperature).  
2. Pobierz z bazy measurements ostatnie 3 pomiary dla tego sensora, sortując malejąco po timestamp.  
3. **Analiza Warunkowa:**  
   * **Jeśli nowa temperatura \> 10°C:**  
     * Ustaw zmienną new\_interval na 'alert\_5'.  
     * Sprawdź historię: Jeśli 2 poprzednie pomiary również były \> 10°C (łącznie 3 z rzędu), ustaw flagę is\_alarm \= true.  
     * Wywołaj (zamarkuj w kodzie) zewnętrzne API Efento (PUT /devices/{id}/configuration) aby fizycznie zmienić interwał pomiarowy sensora na 5 minut.  
   * **Jeśli nowa temperatura \<= 10°C:**  
     * Ustaw zmienną new\_interval na 'standard\_15'.  
     * Jeśli poprzedni stan to 'alert\_5', przywróć konfigurację sensora na 15 minut.  
4. **Powiadomienia:**  
   * Jeśli is\_alarm \= true, pobierz listę kontaktów (Role: Manager, Owner) z tabeli profiles i wyślij natychmiastowy e-mail (użyj Resend API) oraz SMS (użyj Twilio API lub innego dostawcy).  
5. Zapisz nowy pomiar w tabeli measurements.

Wygeneruj kompletny kod w TypeScript, gotowy do deploymentu."

## ---

**6\. Moduły M03 i M04: Dynamiczne Procesy i Checklisty (GMP/GHP)**

W tych modułach kluczowa jest elastyczność i brak blokad operacyjnych. Zgodnie z wersją 03-00, system nie wymusza "Działania Korygującego" przed zamknięciem karty, co przyspiesza pracę.3

### **6.1. Generator Checklist**

**Prompt dla Junior Developera (Fast Mode):**

"Stwórz uniwersalny widget ChecklistForm w Flutterze, który dynamicznie buduje interfejs na podstawie konfiguracji JSON (lista pytań).

**Wymagania UI:**

1. Dla każdego pytania (np. 'Czystość blatów') wygeneruj wiersz z tekstem i dużym przełącznikiem (Switch/Toggle).  
2. Styl Switcha: Zielony (OK) / Czerwony (Problem). Rozmiar min. 60x40dp.  
3. **Logika Biznesowa:** Jeśli użytkownik zaznaczy 'Problem' (Czerwony), automatycznie rozwiń pole tekstowe TextField z placeholderem 'Dodaj komentarz (opcjonalnie)'. Nie blokuj przycisku 'Zatwierdź'.  
4. Przycisk 'Zatwierdź' musi być umieszczony na dole, zajmować całą szerokość i wymagać długiego przyciśnięcia (Long Press) przez 1 sekundę, aby zapobiec przypadkowym kliknięciom.  
5. Dane wyjściowe mają być serializowane do JSON i gotowe do wysyłki do tabeli ghp\_logs."

## ---

**7\. Moduł M05: BDO i Dokumentacja Fotograficzna**

Integracja z BDO wymaga precyzyjnego mapowania kodów odpadów oraz dowodów w postaci zdjęć certyfikatów.3

### **7.1. Implementacja Kamery i Uploadu**

**Prompt dla Junior Developera:**

"Napisz serwis WasteManagementService w Dart, obsługujący proces ewidencji odpadów.

**Funkcjonalność:**

1. Metoda captureAndUploadPhoto():  
   * Uruchom aparat urządzenia.  
   * Po zrobieniu zdjęcia, skompresuj je (max 1024x1024px, jakość 80% JPEG).  
   * Wyślij plik do Supabase Storage do bucketa waste-certificates.  
   * Struktura ścieżki: /{YEAR}/{MONTH}/{venue\_id}\_{timestamp}.jpg (organizacja datami jest kluczowa dla archiwizacji).  
   * Zwróć publiczny URL zdjęcia.  
2. Metoda submitWasteRecord(String wasteCode, double weight, String photoUrl):  
   * Zapisz rekord w tabeli waste\_records.

Dodaj obsługę błędów sieciowych – jeśli upload się nie powiedzie, zapisz zdjęcie lokalnie i ponów próbę, gdy wróci połączenie (Queueing)."

## ---

**8\. Moduł M06: Raportowanie i Synchronizacja z Google Drive**

To "tarcza ochronna" przed Sanepidem. Raporty muszą imitować papierowe wzory i być archiwizowane poza systemem (Google Drive).3

### **8.1. Generator PDF (Backend)**

Ze względu na złożoność i obciążenie, generowanie PDF odbywa się w chmurze (Edge Function), a nie na tablecie.

**Prompt dla Senior Architekta (Planning Mode):**

"Zaprojektuj Supabase Edge Function generate-daily-report, uruchamianą przez CRON codziennie o 23:55.

**Kroki logiczne:**

1. Iteruj przez wszystkie aktywne venues.  
2. Pobierz dane z ostatnich 24h z tabel: measurements, ghp\_logs, gmp\_logs, waste\_records.  
3. Użyj biblioteki pdfmake (Node.js) do wygenerowania dokumentu PDF.  
4. **Styl:** Dokument musi wyglądać jak oficjalny protokół. Strona 1: Tabela temperatur. Strona 2: Rejestr higieny. Strona 3: Odpady. Nagłówki: Data, Nazwa Lokalu, Podpis Managera.  
5. Zapisz wygenerowany PDF tymczasowo w pamięci."

### **8.2. Integracja Google Drive API**

**Kontynuacja Promptu (Integracja):**

"Rozszerz funkcję o eksport do Google Drive.

1. Użyj konta serwisowego Google (Service Account). Klucze JSON pobierz bezpiecznie z Supabase Vault.  
2. Dla każdego lokalu pobierz google\_drive\_folder\_id z tabeli venues.  
3. Prześlij plik PDF do odpowiedniego folderu.  
4. Format nazwy pliku: HACCP\_{YYYY-MM-DD}\_{VenueName}.pdf.  
5. Zaktualizuj status w tabeli logów systemowych: report\_status \= 'synced'."

## ---

**9\. Moduł M07: HR i System Powiadomień**

Moduł ten działa w tle, monitorując ważność badań. Kluczowa zmiana w v03-00: brak blokady logowania dla pracowników z przeterminowanymi badaniami.3

**Prompt dla Junior Developera:**

"Stwórz funkcję bazodanową PostgreSQL (Stored Procedure) check\_sanepid\_expiry, która będzie uruchamiana przez pg\_cron raz dziennie.

**Logika:**

1. Wybierz pracowników (profiles), których sanepid\_checkup\_expiry przypada za 30, 14 lub 7 dni.  
2. Dla każdego takiego przypadku, wyślij e-mail do Managera powiązanego z danym venue\_id. Treść: 'Pracownikowi {Name} wygasają badania w dniu {Date}'.  
3. Zaktualizuj pole notification\_status w profilu pracownika, aby nie wysyłać tego samego powiadomienia wielokrotnie.  
4. Upewnij się, że funkcja NIE zmienia flagi is\_active użytkownika – dostęp ma pozostać otwarty."

## ---

**10\. Procedura Wdrożenia i Audytu (The Nerd Persona)**

Ostatnim etapem jest weryfikacja jakości i bezpieczeństwa. Wykorzystamy personę "The Nerd" do audytu wygenerowanego kodu.2

### **10.1. Audyt Jakościowy**

**Prompt dla Audytora (Audit Mode):**

"Aktywuj personę 'The Nerd'. Przeprowadź kompleksowy audyt wygenerowanego kodu Fluttera i funkcji backendowych.

**Lista Kontrolna:**

1. **Security:** Czy w kodzie Fluttera nie ma zaszytych kluczy API (hardcoded secrets)? Czy Supabase RLS jest włączone dla wszystkich tabel?  
2. **UX Compliance:** Sprawdź pliki widoków – czy wszystkie InkWell / Button mają minimalny rozmiar 48dp? Czy kolory są zgodne z app\_theme.dart?  
3. **Resilience:** Czy funkcje uploadu (M05) mają mechanizm retry w przypadku błędu sieci?

Wygeneruj raport w tabeli Markdown z kolumnami: 'Priorytet', 'Lokalizacja Błędu', 'Sugerowana Poprawka'."

### **10.2. Deployment**

Po zatwierdzeniu poprawek przez "Juniora", następuje wdrożenie:

1. **Backend:** supabase functions deploy.  
2. **Database:** supabase db push (aplikacja migracji).  
3. **Frontend:** Budowa pliku APK (flutter build apk \--release) i instalacja na tabletach za pomocą narzędzi MDM lub ręcznie.

## ---

**11\. Wnioski i Podsumowanie Workflow**

Przedstawiony plan wdrożenia wykorzystuje pełen potencjał Google Antigravity, delegując żmudne zadania kodingowe do AI, podczas gdy programista zachowuje pełną kontrolę nad architekturą.

**Kluczowe czynniki sukcesu:**

1. **Rygorystyczne przestrzeganie Protocol Zero:** Plik Gemini.MD jest gwarantem, że agenci nie zboczą z kursu i będą pamiętać o specyficznych wymogach (np. brak blokad w M07, algorytm 10/5/3).  
2. **Separacja ról:** Użycie modelu Claude do logiki i SQL, a Gemini do UI, optymalizuje jakość kodu.  
3. **Online-First z buforowaniem:** Mimo architektury opartej na chmurze, aplikacja musi być przygotowana na chwilowe utraty łączności (kolejkowanie zdjęć, lokalna pamięć podręczna checklist), co zostało uwzględnione w promptach.

Realizacja tego planu pozwoli na stworzenie systemu, który jest nie tylko zgodny z przepisami, ale przede wszystkim użyteczny dla personelu kuchennego, realizując wizję "niewidzialnej technologii" wspierającej bezpieczeństwo żywności.

Tabela 2\. Harmonogram Wdrożenia dla Zespołu (AI \+ Człowiek)

| Dzień | Moduł | Zadanie Agenta "Senior" (Planowanie) | Zadanie Agenta "Junior" (Kodowanie) |
| :---- | :---- | :---- | :---- |
| **1** | Setup & DB | Projekt Schematu SQL, RLS, API Kontrakty. | Migracja bazy Supabase, Inicjalizacja projektu Flutter. |
| **2** | M01 Core | Architektura autoryzacji. | UI Logowania, Obsługa Kiosk Mode (Android Channel). |
| **3** | M02 IoT | Logika Edge Function (10/5/3). | Integracja Webhooków Efento, Dashboard Monitoringu. |
| **4** | M03/M04 | Modele danych JSONB dla formularzy. | Dynamiczne widgety Checklist, obsługa gestów. |
| **5** | M05 BDO | Strategia Storage (ścieżki, uprawnienia). | Obsługa kamery, kompresja zdjęć, upload. |
| **6** | M06 Report | Projekt PDF (pdfmake), Integracja Google API. | Edge Function CRON, wiązanie konta Google. |
| **7** | QA & Deploy | Audyt bezpieczeństwa i wydajności. | Poprawki błędów, Build produkcyjny, Dokumentacja. |

#### **Cytowane prace**

1. Antigravity\_ Tips, Tricks, and Best Practices.txt  
2. Budowanie Automatyzacji z Antygrawitacją Krok po Kroku.txt  
3. Specyfikacja Wymagań Projektu HACCP Pilot 03-00.txt  
4. Kurs Google AntiGravity\_ Od Podstaw do Klienta.txt  
5. Tutorial Budowania Aplikacji z Antigravity.txt  
6. Budowa Oprogramowania z AntiGravity\_ Poradnik.txt