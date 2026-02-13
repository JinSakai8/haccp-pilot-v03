# **Raport Architektury Referencyjnej i Strategii Wdrożeniowej Systemu Zarządzania Bezpieczeństwem Żywności „HACCP Pilot”: Studium Transformacji Cyfrowej w Paradygmacie Online-First i Agentic Development**

## **1\. Wstęp: Kontekst Strategiczny i Ewolucja Systemów FSMS w Dobie Przemysłu 4.0**

Transformacja cyfrowa sektora gastronomicznego oraz przetwórstwa spożywczego, często określana mianem "Gastronomii 4.0", wymusza fundamentalną redefinicję podejścia do Systemów Zarządzania Bezpieczeństwem Żywności (Food Safety Management Systems \- FSMS). Tradycyjne metody, oparte na reaktywnym wypełnianiu papierowej dokumentacji, stają się niewydolne w konfrontacji z rosnącą złożonością łańcuchów dostaw, rygoryzmem legislacyjnym (polskie wymogi Sanepidu i BDO) oraz presją ekonomiczną na optymalizację kosztów operacyjnych. Projekt "HACCP Pilot" w wersji 03-00 stanowi odpowiedź na te wyzwania, proponując architekturę referencyjną dla zautomatyzowanego, ciągłego nadzoru nad parametrami krytycznymi, wykorzystującą najnowsze osiągnięcia w dziedzinie Internetu Rzeczy (IoT), chmury obliczeniowej oraz inżynierii oprogramowania wspomaganej sztuczną inteligencją (Agentic Development).1

Niniejszy raport stanowi wyczerpującą analizę techniczną, funkcjonalną i biznesową systemu, ze szczególnym uwzględnieniem strategicznego zwrotu (pivotu) z architektury "Offline-First" na "Online-First". Decyzja ta, podyktowana rosnącą niezawodnością infrastruktury telekomunikacyjnej (LTE/5G) oraz potrzebą natychmiastowej synchronizacji danych ("Single Source of Truth"), redefiniuje logikę działania aplikacji, przenosząc ciężar przetwarzania i składowania danych na centralną bazę Supabase.1 Analiza obejmuje również unikalną metodologię wytwórczą wykorzystującą środowisko Google Antigravity, która zmienia rolę programisty z koodera na architekta zarządzającego flotą autonomicznych agentów AI, co pozwala na bezprecedensową szybkość i precyzję wdrażania zmian w kodzie zgodnie z rygorystycznymi specyfikacjami.1

Celem opracowania jest dostarczenie kompletnego "planu gry" (blueprint) dla interesariuszy, architektów systemowych i audytorów jakości, demonstrującego, w jaki sposób integracja zaawansowanej telemetrii (Efento NB-IoT), automatyzacji sprawozdawczości urzędowej (BDO API) oraz cyfrowego obiegu dokumentów (Google Drive API) tworzy spójny ekosystem bezpieczeństwa żywności, zgodny ze standardami HACCP, GMP i GHP.1

## **2\. Metodologia Wytwórcza: Paradygmat Agent-First i Inżynieria Intencji**

Projekt "HACCP Pilot" wyróżnia się na tle konwencjonalnych rozwiązań IT przyjęciem nowatorskiej metodologii "Agent-First Development". W tym modelu proces tworzenia oprogramowania przestaje być sekwencją manualnego pisania kodu, a staje się procesem orkiestracji pracy intelektualnej wykonywanej przez autonomiczne modele językowe (LLM), takie jak Gemini 3 Pro czy Claude 3.5 Sonnet, działające w środowisku Google Antigravity.3

### **2.1 Spec-Driven Development (SDD) i Architektura Spec Kit**

Fundamentem integralności projektu jest metodologia Spec-Driven Development (SDD). W przeciwieństwie do tradycyjnych metodyk zwinnych (Agile), gdzie dokumentacja często nie nadąża za zmianami w kodzie, SDD narzuca rygor, w którym specyfikacja jest wykonywalnym artefaktem poprzedzającym implementację. Wykorzystanie zestawu narzędzi "Spec Kit" pozwala na sformalizowanie wymagań w strukturę plików Markdown, które są zrozumiałe zarówno dla ludzi, jak i dla agentów AI, stanowiąc nienaruszalny punkt odniesienia dla generowanego kodu.5

#### **2.1.1 Konstytucja Projektu (constitution.md)**

Plik constitution.md pełni rolę "DNA" projektu. Zawiera on nienaruszalne zasady (North Star principles), ograniczenia architektoniczne oraz standardy jakości, do których agenty muszą się stosować bezwzględnie. Dla systemu HACCP Pilot, konstytucja definiuje priorytet architektury "Online-First", zakaz blokowania dostępu pracownikom z przeterminowanymi badaniami (zmiana filozofii z restrykcji na nadzór w wersji 03-00) oraz wymóg generowania raportów PDF w formacie "Sanepid-Ready".1 Jest to warstwa governance, która zapobiega dryfowi kontekstowemu (context drift), typowemu dla długich sesji pracy z LLM, gwarantując, że każdy wygenerowany moduł jest zgodny z nadrzędną strategią biznesową.

#### **2.1.2 Specyfikacja Funkcjonalna (spec.md)**

Dokument ten tłumaczy wymagania biznesowe na język atomowych historii użytkownika i ograniczeń funkcjonalnych. W kontekście omawianego systemu, spec.md precyzuje m.in. logikę algorytmu alarmowego "10/5/3" dla modułu monitoringu, strukturę pól dla arkuszy pieczenia mięs w module GMP oraz wymóg dokumentacji fotograficznej w module BDO.1 Stanowi on bezpośrednią instrukcję dla agenta o personie "Architekta", definiującą *co* ma zostać zbudowane, z dokładnością do pojedynczego pola w bazie danych.

#### **2.1.3 Plan Techniczny (tech-plan.md)**

Podczas gdy specyfikacja odpowiada na pytanie *co*, plan techniczny definiuje *jak*. Dokument ten mapuje wymagania funkcjonalne na konkretny stos technologiczny (Tech Stack): Flutter dla warstwy prezentacji, Supabase dla backendu, protokół CoAP dla komunikacji z sensorami Efento. tech-plan.md zawiera również wskazówki (hints) dotyczące schematu bazy danych, np. relacje między tabelami sensor\_logs, users i waste\_records, oraz wzorce integracyjne dla zewnętrznych API, takich jak Google Drive czy BDO.1 Jest to mapa drogowa dla agentów o personie "Budowniczego" (The Builder).

#### **2.1.4 Zadania Atomowe (tasks.md)**

Aby zarządzać probabilistyczną naturą modeli językowych i zminimalizować ryzyko halucynacji, złożone cele projektowe są dekomponowane na granularne, "atomowe" zadania w pliku tasks.md. Zadanie takie jak "Integracja z BDO" jest rozbijane na serię kroków: "Zaimplementuj mapowanie czynności smażenia na kod odpadu 20 01 25", "Stwórz endpoint do przesyłania zdjęcia zaświadczenia", "Zapisz metadane zdjęcia w tabeli waste\_logs".8 Taka granulacja umożliwia precyzyjną weryfikację (unit testing) każdego kroku i pozwala na skuteczne zastosowanie mechanizmów samonaprawczych (Self-Healing Loops).

### **2.2 Zaawansowana Orkiestracja: Frameworki BLAST, RAPS i DOE**

Praca w środowisku Antigravity opiera się na ustrukturyzowanych frameworkach, które systematyzują interakcję między architektem (człowiekiem) a wykonawcą (AI). Analiza materiałów źródłowych pozwala wyodrębnić kluczowe metodologie stosowane w projekcie.

#### **2.2.1 Framework BLAST (Cykl Życia Produktu)**

* **Blueprint (Plan):** Faza inicjalizacji, w której tworzony jest plik Gemini.MD, definiujący wizję i źródła prawdy. Dla HACCP Pilot jest to moment określenia Supabase jako SSOT.4  
* **Links (Połączenia):** Ustanowienie i weryfikacja połączeń z narzędziami zewnętrznymi poprzez protokół MCP (Model Context Protocol). Przykładem jest "Wirtualny Uścisk Dłoni" (Virtual Handshake) z API Supabase i Google Drive przed rozpoczęciem kodowania.4  
* **Architect (Architektura):** Tworzenie Standardowych Procedur Operacyjnych (SOP) w formie plików Markdown, które służą jako instrukcje dla agentów wykonawczych. Zasada "Logic changes \-\> Update SOP \-\> Update Code" zapewnia determinizm działania systemu.4  
* **Stylize (Stylizacja):** Wykorzystanie multimodalnych zdolności modelu Gemini 3.0 do generowania interfejsu użytkownika na podstawie dostarczonych zrzutów ekranu (np. wzorów papierowych arkuszy Sanepidu).4  
* **Trigger (Wyzwalacz):** Faza wdrożenia i automatyzacji, np. konfiguracja zadań Cron w chmurze do codziennego generowania raportów PDF.4

#### **2.2.2 Framework RAPS (Struktura Operacyjna)**

* **Rules (Zasady):** Egzekwowanie reguł zawartych w constitution.md, takich jak wymóg obsługi interfejsu w rękawiczkach lateksowych.4  
* **Armory (Zbrojownia):** Zbiór konkretnych "Umiejętności" (Skills) dostępnych dla agenta, np. skrypt Python do parsowania faktur lub moduł komunikacji z API Efento.4  
* **Parallel Agents (Agenci Równolegli):** Wykorzystanie wyspecjalizowanych person – "The Builder" (backend), "The Design Lead" (frontend), "The Nerd" (QA/Security) – pracujących jednocześnie nad różnymi aspektami systemu, co drastycznie skraca czas developmentu.4  
* **Serverless:** Implementacja logiki biznesowej (np. analiza algorytmu 10/5/3) jako funkcji bezserwerowych (Edge Functions), co odciąża urządzenia klienckie.4

#### **2.2.3 Model DOE: Directive, Orchestration, Execution**

Aby pogodzić kreatywność AI z deterministycznymi wymogami oprogramowania bankowego czy medycznego (a takim jest w istocie system HACCP), stosuje się model DOE:

* **Directive (Dyrektywa):** Człowiek definiuje intencję w języku naturalnym (np. "Zaimplementuj mechanizm Safety Override dla alarmów").  
* **Orchestration (Orkiestracja):** Agent "Menedżer" interpretuje dyrektywę, planuje zmiany w plikach i przydziela zadania.  
* **Execution (Wykonanie):** Agenci "Robotnicy" generują deterministyczny kod (Dart/SQL), który realizuje logikę. Taka separacja gwarantuje, że o ile proces tworzenia jest wspomagany AI, o tyle wynikowy kod jest przewidywalny i audytowalny.2

## **3\. Ewolucja Architektoniczna: Imperatyw Online-First**

Przejście z wersji 01/02 do wersji 03-00 (z datą aktualizacji 03 lutego 2026\) stanowi kluczowy moment w rozwoju systemu HACCP Pilot. Jest to odejście od skomplikowanej architektury "Offline-First" na rzecz usprawnionego modelu "Online-First".1

### **3.1 Rezygnacja ze Złożoności Offline**

Wcześniejsze iteracje systemu kładły nacisk na pełną autonomię urządzenia w warunkach braku sieci, wykorzystując lokalne bazy danych NoSQL (Isar/Hive) i zaawansowane kolejki synchronizacyjne typu "Store-and-Forward".1 Choć technicznie imponujące, rozwiązanie to generowało znaczny narzut związany z rozwiązywaniem konfliktów (strategie Last Write Wins, zegary Lamporta), zarządzaniem lokalnymi UUID oraz spójnością danych w systemie rozproszonym. W obliczu powszechnej dostępności stabilnych łączy LTE/5G nawet w trudnych lokalizacjach, utrzymywanie tak złożonej architektury uznano za nieekonomiczne i ryzykowne z punktu widzenia integralności danych.1

### **3.2 Supabase jako Single Source of Truth (SSOT)**

W nowej architekturze, baza danych Supabase przestaje być jedynie celem synchronizacji, a staje się autorytatywnym stanem systemu (Single Source of Truth).

* **Realtime Subscriptions:** Aplikacja kliencka Flutter subskrybuje zmiany w bazie danych za pośrednictwem protokołu WebSocket (mechanizm Supabase Realtime). Gdy sensor IoT zapisze nowy odczyt temperatury, panel managera aktualizuje się natychmiastowo, bez konieczności odpytywania serwera (polling).1  
* **PostgreSQL Backend:** Relacyjna integralność danych (np. powiązanie CleaningLog z konkretnym Employee i Zone) jest egzekwowana na poziomie bazy danych, co eliminuje ryzyko korupcji danych, możliwe w przypadku luźnych struktur lokalnych.  
* **Cloud Storage:** Zdjęcia weryfikacyjne dla modułu Zarządzania Odpadami (BDO) są przesyłane bezpośrednio do Supabase Storage, co odciąża pamięć urządzeń lokalnych i umożliwia natychmiastowy audyt przez osoby uprawnione z dowolnego miejsca.1

## **4\. Warstwa Percepcyjna: Integracja Przemysłowego IoT**

Wiarygodność każdego systemu HACCP zależy od precyzji i ciągłości pomiarów telemetrycznych. HACCP Pilot wykorzystuje zaawansowany stos technologiczny IoT, zaprojektowany specjalnie do pracy w "wrogim" środowisku radiowym kuchni przemysłowych i chłodni.

### **4.1 Architektura Sensorów Efento NB-IoT**

System opiera się na sensorach marki Efento, wykorzystujących technologię Narrowband IoT (NB-IoT). Jest to standard sieci komórkowej zoptymalizowany pod kątem głębokiej penetracji przeszkód (np. betonowe ściany piwnic) oraz minimalnego zużycia energii. Wybór ten jest bezpośrednią odpowiedzią na problem "klatki Faradaya", powszechny w gastronomii, gdzie metalowe komory chłodnicze skutecznie blokują sygnały WiFi, czyniąc standardowe rozwiązania konsumenckie bezużytecznymi.1

#### **4.1.1 Strategia Mitygacji Klatki Faradaya**

W celu zapewnienia nieprzerwanej łączności, przyjęto rygorystyczną strategię montażu "zewnętrznego". Jednostka centralna sensora, zawierająca modem radiowy i antenę, jest montowana magnetycznie na *zewnętrznej* ścianie komory chłodniczej. Do wnętrza wprowadzana jest jedynie płaska, specjalistyczna sonda pomiarowa na przewodzie o długości 1 metra. Przewód ten jest na tyle cienki, że swobodnie mieści się pod uszczelką drzwi, nie naruszając termicznej szczelności urządzenia. Taka konfiguracja gwarantuje, że element radiowy ma zawsze zasięg sieci komórkowej, a element pomiarowy znajduje się w punkcie krytycznym.1

### **4.2 Konfiguracja i Profile Telemetryczne**

Osiągnięcie kompromisu między gęstością danych (wymaganą przez Sanepid) a żywotnością baterii (cel: 2-5 lat bezobsługowej pracy na bateriach litowych) wymaga precyzyjnej parametryzacji cyklu pracy sensora.

Tabela 1\. Parametry konfiguracyjne sensorów Efento NB-IoT w systemie HACCP Pilot

| Parametr Konfiguracyjny | Wartość | Uzasadnienie Techniczne i Operacyjne |
| :---- | :---- | :---- |
| **Interwał Pomiarowy** | 15 Minut | Zgodność z wymogami Sanepidu dla monitoringu Krytycznych Punktów Kontroli (CCP); umożliwia wykrycie trendu wzrostowego temperatury zanim dojdzie do rozmrożenia towaru.1 |
| **Interwał Transmisji** | 60 Minut | Grupowanie 4 pomiarów w jedną paczkę transmisyjną w celu minimalizacji liczby sesji nawiązywania połączenia radiowego ("handshake"), co jest procesem najbardziej energochłonnym.1 |
| **Safety Override** | Natychmiast | Mechanizm bezpieczeństwa: w przypadku przekroczenia progu alarmowego (np. \>10°C), sensor ignoruje bufor i natychmiast inicjuje transmisję alertu.1 |
| **APN** | iot.1nce.net | Specyficzna konfiguracja dla kart SIM operatora 1NCE, wykorzystująca uwierzytelnianie PAP.1 |
| **Zasilanie** | Baterie Litowe | Wymóg stosowania ogniw litowych (np. Energizer Ultimate Lithium) ze względu na ich stabilną charakterystykę rozładowania w niskich temperaturach (do \-20°C).1 |

### **4.3 Protokoły Komunikacyjne: CoAP i DTLS**

W celu maksymalizacji wydajności w sieci wąskopasmowej, system rezygnuje z protokołów HTTP czy MQTT na rzecz Constrained Application Protocol (CoAP) działającego na warstwie transportowej UDP.

* **Efektywność Energetyczna:** UDP eliminuje narzut związany z utrzymywaniem stałych połączeń TCP i wieloetapowym nawiązywaniem sesji (handshake), co drastycznie skraca czas aktywności modemu radiowego ("Time on Air").1  
* **Serializacja:** Dane są serializowane przy użyciu formatu Protocol Buffers (Protobuf), który jest formatem binarnym, znacznie lżejszym od tekstowych formatów JSON czy XML, co dodatkowo oszczędza pasmo i baterię.1  
* **Bezpieczeństwo:** Integralność i poufność danych są zapewnione przez protokół Datagram Transport Layer Security (DTLS), który oferuje poziom szyfrowania analogiczny do TLS, ale dla pakietów UDP, chroniąc system przed atakami typu Man-in-the-Middle oraz podsłuchem.1

## **5\. Architektura Funkcjonalna: Ekosystem Modułowy**

Logika aplikacji została podzielona na pięć odrębnych, ale ściśle zintegrowanych modułów, z których każdy adresuje specyficzny aspekt zgodności z normami bezpieczeństwa żywności. Zmiany wprowadzone w wersji 03-00 mają kluczowe znaczenie dla ergonomii i efektywności operacyjnej.

### **5.1 Moduł M01: Zarządzanie Tożsamością i Dostępem**

Moduł ten zarządza aspektami "kto" i "gdzie" w systemie operacyjnym.

* **Hierarchia Struktur:** System wymusza sztywną strukturę organizacyjną: Firma ![][image1] Lokal ![][image1] Strefa. Strefowanie to pozwala na kontekstowe dopasowanie interfejsu (Context Awareness), gdzie tablet zamontowany w "Strefie Obróbki Mięsa" wyświetla tylko zadania i parametry relewantne dla tego obszaru, redukując szum informacyjny i ryzyko pomyłki.1  
* **Tryb Kiosk:** Uznając specyfikę dynamicznego środowiska kuchennego, zaimplementowano "Tryb Kiosk", umożliwiający szybkie przełączanie użytkowników za pomocą prostego kodu PIN, zamiast uciążliwego logowania hasłem.1  
* **Transformacja Logiki HR (Nadzór zamiast Restrykcji):** Kluczową zmianą w wersji 03-00 jest odejście od modelu restrykcyjnego. Wcześniej pracownik z przeterminowaną książeczką Sanepidu był blokowany przez system. Nowa logika pozwala na kontynuację pracy, ale uruchamia agresywny system powiadomień do menedżera (na 30, 14 i 7 dni przed upływem ważności), priorytetyzując ciągłość operacyjną nad sztywną blokadą.1

### **5.2 Moduł M02: Inteligentny Monitoring i Algorytm 10/5/3**

Moduł ten przetwarza telemetrię z warstwy IoT, nakładając na surowe dane zaawansowaną logikę biznesową w celu eliminacji fałszywych alarmów.

* **Algorytm 10/5/3:** Jest to heurystyka określająca reakcję systemu na odchylenia termiczne.  
  * **Warunek:** Jeśli temperatura przekroczy próg **10°C**.  
  * **Reakcja:** System automatycznie zwiększa częstotliwość próbkowania do co **5 minut**.  
  * **Alarm:** Krytyczne powiadomienia (SMS/Email do Właściciela i Managera) są wysyłane dopiero po zarejestrowaniu **3 kolejnych** pomiarów powyżej progu. Pozwala to na odfiltrowanie chwilowych skoków temperatury spowodowanych np. cyklem odszraniania (defrost) lub otwarciem drzwi podczas dostawy, zapobiegając zjawisku "zmęczenia alarmami" (alert fatigue).1  
* **Adnotacje:** Personel ma możliwość oznaczania punktów na wykresie kontekstowymi etykietami (np. "Dostawa", "Mycie"). Co kluczowe, system wymusza nienaruszalność (immutability) surowych danych z sensorów – adnotacje są warstwą metadanych nakładaną na wykres, co gwarantuje wiarygodność ścieżki audytu (Audit Trail).1

### **5.3 Moduł M03: Cyfryzacja Procesów GMP/GHP**

Moduł ten zastępuje tradycyjne "ściany z podkładkami" interaktywnymi formularzami cyfrowymi, ściśle podzielonymi na Dobrą Praktykę Produkcyjną (GMP) i Dobrą Praktykę Higieniczną (GHP).

* **Arkusze GMP:** Obejmują procesy krytyczne dla bezpieczeństwa produktu: Monitorowanie Pieczenia Mięs, Rejestry Chłodzenia Szokowego oraz Kontrolę Dostaw (z nowym, obowiązkowym wymogiem weryfikacji pod kątem obecności szkodników).1  
* **Rejestry GHP:** Służą do monitorowania higieny środowiska: Personel (czystość rąk, ubiór, brak biżuterii), Powierzchnie/Podłogi oraz Sprzęt (stan desek, noży).  
* **Konserwacja:** Nowo wprowadzony podmoduł śledzi procesy dezynfekcji i konserwacji sprzętu kapitałowego (piece, termomixy, frytownice), tworząc cyfrowy dziennik życia każdego urządzenia.1  
* **Elastyczność Operacyjna:** W wersji 03-00 usunięto "sztywną blokadę", która wymuszała wpisanie Działania Korygującego przed zamknięciem karty niespełniającej norm. Uznano, że nie każde odchylenie wymaga natychmiastowej, formalnej remediacji w systemie, oddając decyzyjność w ręce przeszkolonego personelu.1  
* **Ergonomia (Glove-Friendly UX):** Interfejs użytkownika został zaprojektowany z myślą o obsłudze w rękawiczkach lateksowych – duże elementy dotykowe, minimalizacja wpisywania tekstu na rzecz list wyboru i suwaków.1

### **5.4 Moduł M04: Zarządzanie Odpadami i Integracja z BDO**

Moduł ten adresuje skomplikowane wymogi prawne związane z Bazą Danych o Produktach i Opakowaniach oraz Gospodarce Odpadami (BDO).

* **Automatyczne Mapowanie:** System tłumaczy potoczne czynności kuchenne (np. "wylanie frytury") na specyficzne, ustawowe kody odpadów (np. 20 01 25 dla olejów i tłuszczów jadalnych). Ta warstwa abstrakcji upraszcza proces compliance dla personelu nietechnicznego.1  
* **Dowody Wizualne:** Specyficznym wymogiem wersji 03-00 jest dokumentacja fotograficzna Kart Przekazania Odpadu (KPO) lub zaświadczeń od firm zewnętrznych. Zdjęcia te są wykonywane bezpośrednio w aplikacji i automatycznie sortowane w folderach z datami w chmurze (Supabase Storage), tworząc niepodważalny cyfrowy ślad dla audytów środowiskowych.1

### **5.5 Moduł M05: Raportowanie i Archiwizacja**

Moduł ten zamyka pętlę danych, przekształcając cyfrowe logi w prawnie uznawane dokumenty.

* **Generator PDF "Sanepid-Ready":** System wykorzystuje silnik renderujący do tworzenia plików PDF, które wizualnie imitują tradycyjne, papierowe wzory formularzy, do których przyzwyczajeni są inspektorzy sanitarni. Ten zabieg psychologiczny ułatwia proces kontroli i zmniejsza tarcie na linii przedsiębiorca-urząd.1  
* **Synchronizacja z Google Drive:** Wykorzystując Google Drive API, system wykonuje automatyczny, codzienny zrzut wszystkich wygenerowanych raportów. Tworzy to niezależne, redundantne "Archiwum Cyfrowe", do którego właściciel ma dostęp nawet w przypadku utraty dostępu do samej platformy aplikacyjnej.1

## **6\. Strategia Implementacji Technicznej**

### **6.1 Stos Technologiczny (Tech Stack)**

* **Frontend:** Wykorzystanie frameworka **Flutter** (język Dart) pozwala na kompilację do kodu natywnego zarówno dla Androida, jak i iOS z jednej bazy kodu. Zapewnia to spójność działania na heterogenicznej flocie urządzeń spotykanej w gastronomii.1  
* **Backend:** **Supabase** dostarcza spójne środowisko backend-as-a-service, integrujące bazę PostgreSQL, system uwierzytelniania (obsługa logiki PIN w trybie Kiosk), subskrypcje Realtime oraz magazyn plików (Storage).1  
* **Edge Functions:** Funkcje bezserwerowe (prawdopodobnie w ramach Supabase Edge Functions) obsługują logikę przetwarzania algorytmu "10/5/3" w chmurze oraz harmonogramowane (Cron) generowanie raportów dziennych PDF.1

### **6.2 Bezpieczeństwo i Integralność Danych**

* **Szyfrowanie:** Wszystkie dane w tranzycie są szyfrowane: komunikacja aplikacji przez SSL/TLS (HTTPS), a komunikacja sensorów przez DTLS. Dane w spoczynku w bazie Supabase są również szyfrowane.1  
* **Nienaruszalność (Immutability):** Schemat bazy danych został zaprojektowany tak, aby traktować logi z sensorów jako dane typu "append-only". Raz zapisany odczyt temperatury nie może zostać zmieniony, jedynie opatrzony adnotacją. Spełnia to wymogi integralności danych stawiane przez normy takie jak FDA 21 CFR Part 11, które są traktowane jako punkt odniesienia dla najwyższych standardów jakości.1

## **7\. Scenariusze Operacyjne Wdrożenia**

Aby zobrazować działanie systemu w praktyce, przeanalizujmy dwa kluczowe scenariusze.

### **7.1 Scenariusz A: Krytyczna Awaria Łańcucha Chłodniczego**

1. **Detekcja:** Sensor Efento w "Mroźni nr 1" odczytuje temperaturę \-5°C (Próg alarmowy: \-18°C).  
2. **Eskalacja:** Urządzenie wykrywa przekroczenie progu bezpieczeństwa, aktywuje "Safety Override" i natychmiast wysyła dane do chmury, pomijając standardowy bufor godzinny.  
3. **Analiza:** Backend Supabase rejestruje odczyt. Algorytm "10/5/3" (zaadaptowany do progów mroźniczych) rozpoznaje anomalię i wymusza zmianę częstotliwości próbkowania sensora na co 5 minut.  
4. **Potwierdzenie:** Trzy kolejne odczyty w odstępach 5-minutowych potwierdzają utrzymywanie się wysokiej temperatury (eliminacja błędu pomiarowego lub chwilowego otwarcia drzwi).  
5. **Akcja:** System generuje i wysyła alerty SMS oraz Email do Właściciela lokalu.  
6. **Rozwiązanie:** Manager przybywa na miejsce, identyfikuje wybity bezpiecznik, naprawia usterkę i za pomocą tabletu dodaje do logu zdarzeń adnotację "Awaria zasilania \- usunięta". Surowe dane o wzroście temperatury pozostają w systemie jako dowód incydentu.

### **7.2 Scenariusz B: Codzienna Utylizacja Odpadów**

1. **Akcja:** Kucharz zlewa zużyty olej frytury do beczki zbiorczej.  
2. **Logowanie:** W aplikacji na tablecie wybiera opcję "Utylizacja Oleju". System w tle mapuje to działanie na kod BDO 20 01 25\.  
3. **Przekazanie:** Przyjeżdża firma recyklingowa. Kucharz otrzymuje papierowe potwierdzenie odbioru.  
4. **Archiwizacja:** Używając wbudowanej funkcji aparatu w aplikacji, kucharz robi zdjęcie dokumentu. System przesyła je do Supabase/Storage/Waste/2026-02-12/ i linkuje z rekordem w bazie danych.  
5. **Raportowanie:** W nocy automat generuje raport PDF z całego dnia, uwzględniający ilość oddanego oleju, i zapisuje go na Google Drive w folderze "Luty 2026".

## **8\. Podsumowanie i Wnioski**

System HACCP Pilot w wersji 03-00 reprezentuje dojrzałą syntezę nowoczesnej architektury chmurowej i rygoru przemysłowego. Przejście na model "Online-First" pozwoliło na wykorzystanie pełnej mocy obliczeniowej chmury do analizy danych w czasie rzeczywistym, uwalniając system od ograniczeń lokalnego sprzętu. Zastosowanie metodologii "Agent-First" w środowisku Antigravity umożliwiło osiągnięcie tempa rozwoju i jakości kodu, które są trudne do zrealizowania w tradycyjnych modelach programistycznych.

Integracja specjalistycznego sprzętu IoT (odpornego na fizykę klatek Faradaya) z głęboką automatyzacją procesów administracyjnych (BDO, Google Drive) transformuje uciążliwy obowiązek compliance w usprawniony, zautomatyzowany proces tła. System nie tylko cyfryzuje papierologię, ale fundamentalnie zmienia kulturę bezpieczeństwa żywności w organizacji – z modelu opartego na strachu przed kontrolą na model oparty na ciągłej, opartej na danych świadomości operacyjnej. Jest to rozwiązanie klasy Enterprise, skalowalne i gotowe na wyzwania Gastronomii 4.0.

#### **Cytowane prace**

1. Specyfikacja Wymagań Projektu HACCP Pilot 03-00.txt  
2. Budowa Oprogramowania z AntiGravity\_ Poradnik.txt  
3. Antigravity\_ Tips, Tricks, and Best Practices.txt  
4. Tutorial Budowania Aplikacji z Antigravity.txt  
5. Diving Into Spec-Driven Development With GitHub Spec Kit \- Microsoft for Developers, otwierano: lutego 12, 2026, [https://developer.microsoft.com/blog/spec-driven-development-spec-kit](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)  
6. Spec-driven development with AI: Get started with a new open source toolkit \- The GitHub Blog, otwierano: lutego 12, 2026, [https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)  
7. From PRD to Production: My spec-kit Workflow for Structured Development \- Stephan Eberle, otwierano: lutego 12, 2026, [https://steviee.medium.com/from-prd-to-production-my-spec-kit-workflow-for-structured-development-d9bf6631d647](https://steviee.medium.com/from-prd-to-production-my-spec-kit-workflow-for-structured-development-d9bf6631d647)  
8. github/spec-kit: Toolkit to help you get started with Spec-Driven Development, otwierano: lutego 12, 2026, [https://github.com/github/spec-kit](https://github.com/github/spec-kit)  
9. Kurs AntiGravity\_ Od Podstaw do Klienta \- zadania.txt

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABMAAAAYCAYAAAAYl8YPAAAAb0lEQVR4XmNgGAWjYPCCLnQBSoAOEIujC5ILGIG4EkpTBZwH4mB0QRDIAOJHZOB3QPwfiMMZkAAPEEuSiGWAuIMBYigrA4WgDIi3A7EQugSpQBiIbdEFyQV+QMyCLkgumIQuQC4ApS2Kw2kU0AAAAEDXFdpaRGEnAAAAAElFTkSuQmCC>
