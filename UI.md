# HACCP Pilot v03-00 — Specyfikacja UI dla Google Stitch

> **Źródło prawdy (SSOT):** [Gemini.MD.md](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/Gemini.MD.md)
> **Uzupełnienia:** Specyfikacja Projektu V3, Generowanie Aplikacji Krok po Kroku, Dokumentacja Techniczna
> **Platforma docelowa:** Tablet Android (tryb Kiosk), orientacja landscape/portrait
> **Device Type w Stitch:** MOBILE (390px) dla symulacji tabletu w trybie portretowym

---

## Globalne Zasady Designu (Design Tokens)

Te reguły obowiązują **we wszystkich 7 modułach** i muszą być zastosowane w Google Stitch.

| Token | Wartość | Źródło |
|:------|:--------|:-------|
| **Min. Touch Target** | 60×60 dp | Gemini.MD §5C |
| **Font** | Work Sans (bezszeryfowy) | Stitch Project Theme |
| **Min. Font Size (body)** | 18sp | Krok po Kroku §4.1 |
| **Kolor OK** | `#2E7D32` (ciemna zieleń) | Krok po Kroku §4.1 |
| **Kolor Alarm/Błąd** | `#C62828` (ciemna czerwień) | Krok po Kroku §4.1 |
| **Kolor Ostrzeżenie** | `#F9A825` (żółty) | Gemini.MD §5C |
| **Kolor Tło** | `#FFFFFF` | Krok po Kroku §4.1 |
| **Kolor Akcentu** | `#D2661E` (brąz/pomarańcz) | Stitch "Home - Mięso i Piana" |
| **Zaokrąglenie** | 8dp | Stitch Project Theme |
| **Padding przycisków** | 16dp | Krok po Kroku §4.1 |
| **Kolorystyka trybu** | Light Mode | Stitch Project Theme |

> [!IMPORTANT]
> **Zasada "Glove-Friendly":** Żaden przycisk, toggle ani pole nie może być mniejszy niż 48×48dp. Zalecane 60×60dp. Unikamy klawiatury systemowej — używamy dedykowanych NumPadów, Stepperów (+/−) i dużych Toggle Switch.

---

## Nawigacja Główna (Dashboard Hub)

**Ekran startowy po zalogowaniu.** Wyświetla 7 dużych kafelków (tile/card) prowadzących do modułów.

### Układ
>
> **Stitch Screen ID:** `cadac885417e4e1f992c409a2cef9585`

- Siatka 2 kolumny × 4 wiersze (ostatni wiersz: 1 kafelek wycentrowany lub pasek statusu)
- Każdy kafelek: ikona + nazwa modułu + krótki status (np. "2 alarmy", "3 zadania")
- Górny pasek: Nazwa lokalu, Nazwa zalogowanego użytkownika, przycisk Wyloguj (duży, czerwony)

### Kafelki nawigacyjne

| Pozycja | Ikona | Etykieta | Kolor akcentu kafelka |
|:--------|:------|:---------|:----------------------|
| 1 | 🌡️ | Monitoring Temperatur | Niebieski |
| 2 | 🍖 | Procesy GMP | Pomarańczowy |
| 3 | 🧹 | Higiena GHP | Zielony |
| 4 | ♻️ | Odpady BDO | Brązowy |
| 5 | 📊 | Raporty & Archiwum | Fioletowy |
| 6 | 👥 | HR & Personel | Szary |
| 7 | ⚙️ | Ustawienia | Ciemnoszary |

> [!NOTE]
> M01 (Login/Kiosk) nie pojawia się jako kafelek — jest ekranem przed dashboardem. Kafelek "Ustawienia" jest dostępny tylko dla roli `manager` i `owner`.

---

## M01 — Core & Login (Kiosk)

**Cel:** Szybkie logowanie kodem PIN, wybór lokalu/strefy.

### Ekran 1.1: Splash / Branding
>
> **Stitch Screen ID:** `bb89b45a89314b9a8899bcbc5e4354a3`

- Pełnoekranowy
- Logo "HACCP Pilot" i nazwa lokalu "Mięso i Piana"
- Automatyczne przejście do PIN Pad po 2 sekundach

### Ekran 1.2: PIN Pad (główny ekran logowania)
>
> **Stitch Screen ID:** `ea93036fd47e47ee983a97411bbee99a`

- **Centralny element:** Siatka 3×4 przycisków numerycznych (0–9) + "Kasuj" + "Zaloguj"
- Rozmiar każdego przycisku: **80×80 dp** (minimum!)
- Nad klawiaturą: 4–6 kropek wskaźnika wpisanych cyfr (jak w telefonie)
- Kolory przycisków: Ciemne tło z białym tekstem, duży font (24sp+)
- **Przycisk "Zaloguj":** Pełna szerokość, kolor akcentu `#D2661E`
- **Obsługa błędu:** Duży, czerwony komunikat "Błędny PIN" wyświetlany przez 2s, następnie automatyczne wyczyszczenie pola
- **Ostrzeżenie Sanepid:** Jeśli zalogowany pracownik ma przeterminowane badania → żółty banner na górze: "⚠️ Wymagane odnowienie badań Sanepid" (NIE blokuje dostępu!)

### Ekran 1.3: Wybór Strefy (opcjonalny)
>
> **Stitch Screen ID:** `b208b776aee94143a96231a3095c553c`

- Wyświetlany po zalogowaniu, jeśli lokal ma >1 strefę
- Lista dużych kafelków ze strefami: "Kuchnia Gorąca", "Mroźnia", "Magazyn"
- Każdy kafelek: ikona + nazwa, min. 60×80 dp

---

## M02 — Monitoring Temperatur

**Cel:** Dashboard temperatur w czasie rzeczywistym, wykresy, alarmy.

### Ekran 2.1: Dashboard Temperatur (widok główny)
>
> **Stitch Screen ID:** `ab4c4dff668c467b9472733cf14a9761`

- **Górny pasek:** Nazwa strefy, data/godzina, przycisk powrotu do Hub
- **Karty sensorów (lista/siatka):** Dla każdego sensora w strefie:
  - Nazwa sensora (np. "Chłodnia #1")
  - **Aktualna temperatura** — duża czcionka (36sp+), kolor zależny od stanu:
    - ≤10°C → Zielony `#2E7D32`
    - >10°C (ostrzeżenie) → Żółty `#F9A825`
    - Alarm (3 kolejne >10°C) → Czerwony `#C62828` + ikona alarmu 🔔
  - Ostatni pomiar: timestamp
  - Interwał: "Co 15 min" lub "⚡ Co 5 min" (tryb alertowy)
  - Strzałka trendu: ↑ ↓ → (rosnący/malejący/stabilny)

### Ekran 2.2: Wykres Historyczny (szczegóły sensora)
>
> **Stitch Screen ID:** `43621479d33449a7b58a715e79781a58`

- Tap na kartę sensora → przejście do wykresu
- **Wykres liniowy:** Oś X = czas (24h domyślnie), Oś Y = temperatura
- **Linia progowa:** Czerwona linia przerywana na 10°C
- **Adnotacje na wykresie:** Znaczniki z etykietami (np. "Dostawa", "Mycie")
- Przyciski filtrów czasowych: "24h", "7 dni", "30 dni" — duże, z wyraźnym zaznaczeniem aktywnego
- **Przycisk "Dodaj Adnotację":** Otwiera modal z polem tekstowym i listą szybkich etykiet ("Dostawa", "Defrost", "Mycie", "Inne")

### Ekran 2.3: Panel Alarmów
>
> **Stitch Screen ID:** `56527f23be1b406f85ca41c34abb94f7`

- Lista aktywnych alarmów z detalami:
  - Sensor, Temperatura, Czas trwania alarmu
  - Przycisk "Przyjąłem do wiadomości" (Long Press 1s) — nie kasuje alarmu, tylko loguje potwierdzenie
- Historia alarmów (archiwum)

---

## M03 — Procesy GMP (Produkcja)

**Cel:** Cyfrowe karty kontrolne procesów produkcyjnych.

### Ekran 3.1: Wybór Procesu
>
> **Stitch Screen ID:** `10d3e0e2e68844f5be626042b1201c2b`

- 3 duże kafelki (zajmujące pełną szerokość):
  1. 🥩 **Pieczenie Mięs**
  2. ❄️ **Chłodzenie Żywności**
  3. 🚚 **Kontrola Dostaw**
- Każdy kafelek: ikona + nazwa + licznik dzisiejszych wpisów (np. "Dziś: 3 wpisy")

### Ekran 3.2: Formularz — Pieczenie Mięs
>
> **Stitch Screen ID:** `f74607ea977a41c3bceb5127548efb44`

- **Pola formularza:**
  - Produkt → Lista wyboru (dropdown z dużymi pozycjami lub kafelki)
  - Nr Partii → Pole tekstowe (klawiatura numeryczna)
  - Temp. Nastawy Pieca [°C] → **Stepper (+/−)** z domyślną wartością 180°C, krok 5°C
  - Czas Start → Picker godziny (duże kółka)
  - Czas Stop → Picker godziny
  - Temp. Wewnętrzna [°C] → **Stepper (+/−)**, krok 1°C
- **Walidacja miękka:** Jeśli Temp. Wewnętrzna < 75°C → żółty banner: "⚠️ Uwaga: Temperatura poniżej zalecanego minimum 75°C"
- **Przycisk "Zapisz":** Pełna szerokość, kolor zielony, wymaga **Long Press (1s)**

### Ekran 3.3: Formularz — Chłodzenie Żywności
>
> **Stitch Screen ID:** `b7a4044e54cf448a80f6eebe499ed5f7`

- **Pola:**
  - Produkt → Lista wyboru
  - Data Przygotowania → Date Picker
  - Temp. Początkowa [°C] → Stepper (domyślnie >60°C)
  - Godzina Rozpoczęcia → Time Picker
  - Temp. po 2h [°C] → Stepper (walidacja: powinno być <21°C)
  - Temp. Końcowa [°C] → Stepper (walidacja: powinno być <4°C)
  - Godzina Zakończenia → Time Picker
- **Walidacja miękka jak w pieczeniu** — żółte bannery ostrzegawcze, brak blokady

### Ekran 3.4: Formularz — Kontrola Dostaw
>
> **Stitch Screen ID:** `0a4253be7f06423aa4ec6273cd82e539`

- **Pola:**
  - Dostawca → Lista wyboru lub pole tekstowe
  - Nr WZ/Faktury → Pole tekstowe
  - Temp. Transportu [°C] → Stepper
  - Stan Opakowań → **Duże kafelki: Zielony "OK" / Czerwony "Uszkodzone"**
  - Data Ważności → Date Picker
  - **Weryfikacja Szkodników** → **Duże kafelki: Zielony "Brak" / Czerwony "Wykryto"** (pole obowiązkowe!)
- **Przycisk "Zapisz":** Long Press (1s)

### Ekran 3.5: Historia Wpisów GMP
>
> **Stitch Screen ID:** `ccc0814a7a904f419be06a96e0a4e0d5`

- Lista kartkowa (cards) z podsumowaniem: Data, Proces, Produkt, Status (OK/Ostrzeżenie)
- Filtrowanie po typie procesu i dacie

---

## M04 — Higiena GHP (Checklisty)

**Cel:** Dynamiczne listy kontrolne higieny — ODDZIELNY EKRAN od GMP!

### Ekran 4.1: Wybór Kategorii Checklisty
>
> **Stitch Screen ID:** `194f2f4ffccb4ed1b52efaee6ed602f5`

- 4 duże kafelki:
  1. 👤 **Personel** (higiena osobista)
  2. 🏠 **Pomieszczenia** (czystość lokalu)
  3. 🔧 **Konserwacja & Dezynfekcja** (sprzęt)
  4. 🧴 **Środki Czystości** (rejestr chemii)

### Ekran 4.2: Checklista — Personel
>
> **Stitch Screen ID:** `14c0e64c15a743b180992b48c58ad845`

- Dla każdego aktywnego pracownika w strefie (lub wybranego z listy):
  - Nagłówek: Imię i nazwisko pracownika
  - Pozycje checklisty z **dużymi Toggle Switch** (Zielony OK / Czerwony Problem):
    - Czysty ubiór roboczy
    - Brak biżuterii
    - Włosy osłonięte (czepek/siatka)
    - Ręce umyte i zdezynfekowane
  - Jeśli toggle = Czerwony → automatycznie rozwija się pole tekstowe: "Dodaj komentarz (opcjonalnie)"
- **Przycisk "Zatwierdź Checklistę":** Pełna szerokość, Long Press (1s)

### Ekran 4.3: Checklista — Pomieszczenia
>
> **Stitch Screen ID:** `92b0da885ea14c4f85310b9a22a73245`

- Pozycje z Toggle Switch:
  - Czystość podłóg
  - Czystość blatów roboczych
  - Kosze opróżnione
  - Zlew / umywalka czyste
- Logika identyczna jak Personel (toggle + komentarz opcjonalny)

### Ekran 4.4: Checklista — Konserwacja & Dezynfekcja
>
> **Stitch Screen ID:** `88f8bfb8929f4945914047b85d254f6d`

- Lista urządzeń z Toggle Switch:
  - Piec konwekcyjny
  - Chłodnia (każda osobno)
  - Frytownica
  - Toster/Grill
  - Termomix
  - Zmywarka
- Dla każdego: data ostatniego mycia/dezynfekcji (automatyczna)
- Toggle + komentarz opcjonalny

### Ekran 4.5: Rejestr Środków Czystości
>
> **Stitch Screen ID:** `ca10843ee23147d38755e01d1d24e4dd`

- Formularz:
  - Nazwa środka → Lista wyboru lub pole tekstowe
  - Ilość/Stężenie → Stepper lub pole numeryczne
  - Przeznaczenie → Lista wyboru (Podłogi, Blaty, Sprzęt, Ręce)
- Lista dzisiejszych wpisów na dole ekranu

### Ekran 4.6: Historia Checklist
>
> **Stitch Screen ID:** `fce15582b9644e17be1eb10f85e0b2ca`

- Lista z podsumowaniem: Data, Kategoria, Status (Zgodny/Niezgodny), Kto zatwierdził

---

## M05 — Odpady BDO

**Cel:** Ewidencja odpadów z dokumentacją fotograficzną.

### Ekran 5.1: Panel Odpadów (widok główny)
>
> **Stitch Screen ID:** `990f275f86b2450ba6bdcc48aaf2fba2`

- **Przycisk główny:** Duży, wycentrowany: "+ Zarejestruj Odpad" (kolor akcentu)
- Poniżej: Lista ostatnich wpisów (karty):
  - Rodzaj odpadu (potoczna nazwa + kod BDO)
  - Masa [kg]
  - Data
  - Miniatura zdjęcia KPO (jeśli jest)
  - Status: "Zarejestrowany" / "Odebrany"

### Ekran 5.2: Formularz Rejestracji Odpadu
>
> **Stitch Screen ID:** `45244139d51249d79b8ff7c24fe85a95`

- **Pola:**
  - Rodzaj odpadu → **Duże kafelki z potoczną nazwą** (system automatycznie przypisuje kod BDO):
    - "Zużyty olej/frytura" → 20 01 25
    - "Resztki jedzenia" → 20 01 08
    - "Opakowania plastikowe" → 15 01 02
    - "Opakowania papierowe" → 15 01 01
    - "Inne" → pole ręczne z kodem
  - Masa [kg] → **Stepper (+/−)**, krok 0.5 kg
  - Firma Odbierająca → Lista wyboru (zapisane firmy) lub "Nowa firma"
  - Nr KPO → Pole tekstowe (opcjonalne)

### Ekran 5.3: Aparat — Zdjęcie KPO
>
> **Stitch Screen ID:** `b61818becfe748ea9e893cbb4e35f46c`

- Pełnoekranowy podgląd aparatu
- Duży przycisk spustu migawki (80dp)
- Po zrobieniu zdjęcia: Podgląd + przyciski "Ponów" / "Zatwierdź"
- Pasek postępu uploadu do Supabase Storage
- Ścieżka zapisu: `/waste-docs/{venue_id}/{rok}/{miesiąc}/{dzień}/{timestamp}.jpg`

### Ekran 5.4: Historia Odpadów
>
> **Stitch Screen ID:** `236157e708a841519d219926514a3b51`

- Filtry: Okres (miesiąc), Rodzaj odpadu
- Lista z miniaturami zdjęć i podsumowaniem mas

---

## M06 — Raportowanie & Archiwum

**Cel:** Generowanie PDF, status synchronizacji z Google Drive.

### Ekran 6.1: Panel Raportów (widok główny)
>
> **Stitch Screen ID:** `0646209242b54550b07182891b25ace8`

- **Sekcja "Generuj Raport":**
  - Wybór zakresu dat (domyślnie: wczoraj)
  - Wybór typu raportu:
    - 📋 Raport Dzienny (wszystkie moduły)
    - 🌡️ Raport Temperatur
    - 🧹 Raport Higieny GHP
    - 🍖 Raport Procesów GMP
    - ♻️ Raport BDO
  - **Przycisk "Generuj PDF":** Duży, kolor akcentu

- **Sekcja "Ostatnie Raporty":**
  - Lista kart z informacjami:
    - Nazwa raportu + data
    - Status synchronizacji z Google Drive:
      - 🟢 "Zsynchronizowany" (z linkiem do Drive)
      - 🟡 "Oczekuje na sync"
      - 🔴 "Błąd synchronizacji" (z przyciskiem "Ponów")
    - Przycisk "Podgląd PDF"
    - Przycisk "Udostępnij" (wyślij e-mailem)

### Ekran 6.2: Podgląd PDF
>
> **Stitch Screen ID:** `8ad32c828e69495482c8a79600f6507b`

- Wbudowany przeglądnik PDF
- Przyciski: "Zamknij", "Pobierz", "Wyślij na e-mail"

### Ekran 6.3: Status Google Drive
>
> **Stitch Screen ID:** `18fc2d1117b94b368d63d02fc62fec59`

- Informacja o połączeniu z kontem serwisowym
- Struktura folderów: `Archiwum HACCP / {Lokal} / {Rok} / {Miesiąc}`
- Ostatnia synchronizacja: data i godzina
- Przycisk "Synchronizuj teraz"

---

## M07 — HR & Personel (Manager)

**Cel:** Dashboard ważności badań Sanepid, zarządzanie pracownikami.

> [!IMPORTANT]
> Ten moduł jest dostępny **tylko dla ról `manager` i `owner`**.

### Ekran 7.1: Dashboard HR (widok główny)
>
> **Stitch Screen ID:** `9402903814f6427680d9cf071fe3d234`

- **Sekcja alertów (górna):**
  - Karty z pracownikami, którym kończą się badania:
    - 🔴 **Przeterminowane** (czerwone tło) — lista
    - 🟡 **Wygasają w ciągu 30 dni** (żółte tło) — lista
    - 🟢 **Ważne** (zielone tło) — liczba
  - Każda karta pracownika: Imię, Stanowisko, Data wygaśnięcia badań, Dni do wygaśnięcia

### Ekran 7.2: Profil Pracownika
>
> **Stitch Screen ID:** `8b028b4fdd3a4de794bd166b46d75b7d`

- Dane: Imię i nazwisko, Rola, Przypisany lokal/strefa
- **Sekcja "Badania Sanepid":**
  - Data ważności
  - Skan dokumentu (miniatura → tap = pełny podgląd)
  - Przycisk "Aktualizuj badania" → otwiera:
    - Date Picker (nowa data ważności)
    - Aparat/Galeria (nowy skan)
- **Sekcja "Aktywność":**
  - Ostatnie logowania
  - Liczba wykonanych checklist w tym tygodniu
- **Status:** Toggle Aktywny/Nieaktywny (dezaktywacja ≠ usunięcie)

### Ekran 7.3: Dodaj Pracownika
>
> **Stitch Screen ID:** `efe71cf586a04f429197b8d4b80762dd`

- Formularz:
  - Imię i nazwisko
  - Rola → kafelki: "Pracownik" / "Manager"
  - Kod PIN → NumPad (4–6 cyfr) + potwierdzenie
  - Lokal → Lista wyboru
  - Strefa domyślna → Lista wyboru
  - Data badań Sanepid → Date Picker
  - Skan badań → Aparat/Galeria

### Ekran 7.4: Lista Pracowników
>
> **Stitch Screen ID:** `0f4529e4d77b4c9ba67fc8e1eeba3169`

- Sortowalna lista z kolumnami: Imię, Rola, Status Badań (ikona kolorowa), Ostatnie logowanie
- Filtrowanie: Wszyscy / Aktywni / Nieaktywni / Z alertami

---

---

## M08 — Ustawienia Globalne

**Cel:** Konfiguracja systemu, sensorów i interfejsu.

### Ekran 8.1: Ustawienia Globalne
>
> **Stitch Screen ID:** `7a43a321ebd84110b19cfceb434bf9ad`

- **Sensory:** Interwał pomiaru, Powiadomienia Push, Progi alarmowe
- **Interfejs:** Tryb ciemny, Dźwięki
- **Dane Lokalu:** Nazwa, Adres

---

## M09 — UX Polish (Feedback & States)

**Cel:** Ekrany stanów pośrednich dla lepszego User Experience.

### Ekran 9.1: Potwierdzenie Akcji (Success)
>
> **Stitch Screen ID:** `12e6f4f60b48439ba0d03edb92227519`

- **Cel:** Pozytywne wzmocnienie po weykonaniu zadania.
- **Wygląd:** Duża ikona "Check", animacja, zielony akcent.

### Ekran 9.2: Empty State
>
> **Stitch Screen ID:** `de54bb7fedaf4a01a1b0ceab26429407`

- **Cel:** Widok gdy brak zadań/alarmów.
- **Wygląd:** Ilustracja kawy/szefa kuchni, relaksujący komunikat.

### Ekran 9.3: Offline / Błąd Połączenia
>
> **Stitch Screen ID:** `12b6c3d3d64e48bc888d45e483b17d15`

- **Cel:** Informacja o braku sieci.
- **Akcje:** "Spróbuj ponownie", "Pracuj Offline".

---

## Podsumowanie Ekranów do Wygenerowania w Google Stitch

| Moduł | Liczba Ekranów | Ekrany |
|:------|:--------------:|:-------|
| **M01** | 3 | Splash, PIN Pad, Wybór Strefy |
| **Dashboard** | 1 | Hub z 7 kafelkami |
| **M02** | 3 | Dashboard Temperatur, Wykres Historyczny, Panel Alarmów |
| **M03** | 5 | Wybór Procesu, Pieczenie, Chłodzenie, Dostawy, Historia |
| **M04** | 6 | Wybór Kategorii, Personel, Pomieszczenia, Konserwacja, Środki Czystości, Historia |
| **M05** | 4 | Panel Odpadów, Formularz, Aparat KPO, Historia |
| **M06** | 3 | Panel Raportów, Podgląd PDF, Status Drive |
| **M07** | 4 | Dashboard HR, Profil Pracownika, Dodaj Pracownika, Lista |
| **M08** | 1 | Ustawienia Globalne |
| **M09** | 3 | Success, Empty State, Offline |
| **RAZEM** | **33** | |

---

## Kolejność Generowania w Stitch (Rekomendacja)

1. **Faza 1:** M01 (Login) + Dashboard Hub → fundament nawigacji
2. **Faza 2:** M02 (Monitoring) → najważniejszy moduł operacyjny
3. **Faza 3:** M03 (GMP) + M04 (GHP) → formularze produkcyjne i higieniczne
4. **Faza 4:** M05 (BDO) → ewidencja odpadów z aparatem
5. **Faza 5:** M06 (Raporty) + M07 (HR) → moduły zarządcze
