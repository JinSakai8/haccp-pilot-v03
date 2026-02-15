# 🏗️ HACCP Pilot v03 — Sprint Plan: Dopracowanie Aplikacji

> **Cel:** Zidentyfikować brakujące ekrany i niedokończone funkcjonalności w stosunku do specyfikacji UI, następnie zaplanować ich wdrożenie w sprintach.
> **Autor:** Senior Developer (AI)
> **Data:** 2026-02-15
> **Aplikacja:** Działająca na Vercel (Flutter Web), 27 plików ekranów istnieje, ale wiele to stuby.

---

## 📊 Audyt: Co Istnieje vs. Co Jest w Specyfikacji UI

### Legenda statusów

| Status | Opis |
|:-------|:-----|
| ✅ Gotowe | Ekran działa, ma logikę, łączy się z Supabase |
| ⚠️ Częściowe | Ekran istnieje, ale brakuje kluczowych elementów |
| ❌ Stub/Pusty | Plik istnieje, ale to tylko placeholder (tekst "W budowie") |
| 🚫 Brakuje | Pliku w ogóle nie ma lub brak trasy w routerze |

### Tabela stanu ekranów

| # | Ekran | Plik | Status | Co brakuje |
|:--|:------|:-----|:------:|:-----------|
| 1.1 | Splash | `splash_screen.dart` | ✅ | — |
| 1.2 | PIN Pad | `pin_pad_screen.dart` | ✅ | — |
| 1.3 | Wybór Strefy | `zone_selection_screen.dart` | ✅ | — |
| Hub | Dashboard Hub | `dashboard_hub_screen.dart` | ⚠️ | **Hardcoded user/venue name**, brak dynamicznych badge'y, brak role-guard na kafelkach HR/Ustawienia |
| 2.1 | Dashboard Temperatur | `temperature_dashboard_screen.dart` | ⚠️ | Hardcoded `zone_id`, brak nawigacji do wykresu po tap, brak interwału/trendu na karcie |
| 2.2 | Wykres Historyczny | `sensor_chart_screen.dart` | ❌ | **Pusty stub** — tekst "W budowie", brak wykresu `fl_chart`, brak filtrów czasowych, brak adnotacji |
| 2.3 | Panel Alarmów | `alarms_panel_screen.dart` | ❌ | **Pusty stub** — tekst "W budowie", brak listy alarmów, brak przycisku potwierdź |
| 3.1 | Wybór Procesu GMP | `gmp_process_selector_screen.dart` | ✅ | — |
| 3.2 | Pieczenie Mięs | `meat_roasting_form_screen.dart` | ✅ | — |
| 3.3 | Chłodzenie Żywności | `food_cooling_form_screen.dart` | ✅ | — |
| 3.4 | Kontrola Dostaw | `delivery_control_form_screen.dart` | ✅ | — |
| 3.5 | Historia GMP | `gmp_history_screen.dart` | ⚠️ | Brak filtrów (typ procesu, zakres dat) |
| 4.1 | Wybór Kategorii GHP | `ghp_category_selector_screen.dart` | ⚠️ | Przycisk "Historia" ma `onTap: () => {}` — brak nawigacji do `/ghp/history` |
| 4.2-4.4 | Checklisty GHP | `ghp_checklist_screen.dart` | ✅ | Generyczny ekran — działa poprawnie |
| 4.5 | Rejestr Środków Czystości | `ghp_checklist_screen.dart` | ⚠️ | Również przez generyczny ekran, ale spec wymaga osobnego formularza (Dropdown + Stepper + lista dzisiejszych wpisów) |
| 4.6 | Historia GHP | `ghp_history_screen.dart` | ⚠️ | Plik istnieje i działa, ale **brak trasy w routerze** — nie da się na nią nawigować |
| 5.1 | Panel Odpadów | `waste_panel_screen.dart` | ✅ | — |
| 5.2 | Formularz Odpadów | `waste_registration_form_screen.dart` | ⚠️ | Hardcoded `test_venue_id` zamiast realnego ID |
| 5.3 | Aparat KPO | `haccp_camera_screen.dart` | ⚠️ | Placeholder na Web (kamera nie działa w przeglądarce — to jest OK, ale brak fallback z file picker) |
| 5.4 | Historia Odpadów | `waste_history_screen.dart` | ⚠️ | Brak filtrów (miesiąc, rodzaj odpadu), brak sumy mas |
| 6.1 | Panel Raportów | `reports_panel_screen.dart` | ⚠️ | Brak "Raport Dzienny" jako typ, przycisk "Podgląd PDF" wyświetla SnackBar zamiast otwierać przeglądarkę PDF |
| 6.2 | Podgląd PDF | `pdf_preview_screen.dart` | ⚠️ | Nie działa na Web (wymaga patha pliku), brak przycisków Pobierz/Wyślij |
| 6.3 | Status Drive | `drive_status_screen.dart` | ⚠️ | Wymaga sprawdzenia — prawdopodobnie podstawowy |
| 7.1 | Dashboard HR | `hr_dashboard_screen.dart` | ✅ | — |
| 7.2 | Profil Pracownika | `employee_profile_screen.dart` | ❌ | **Totalny placeholder** — tylko `Text('Profile for $id - Placeholder')` |
| 7.3 | Dodaj Pracownika | `add_employee_screen.dart` | ✅ | — |
| 7.4 | Lista Pracowników | `employee_list_screen.dart` | ✅ | — |
| 8.1 | Ustawienia | `global_settings_screen.dart` | ⚠️ | Sekcja System (Tryb Ciemny, Dźwięki) to mock — `onChanged: (v) {}` |
| 9.1 | Success Overlay | `success_overlay.dart` | ✅ | — |
| 9.2 | Empty State | — | 🚫 | **Brak pliku!** Widget `HaccpEmptyState` nie istnieje |
| 9.3 | Offline Banner | `offline_banner.dart` | ✅ | — |

### Brakujące wspólne widgety (M09)

| Widget | Status | Uwagi |
|:-------|:------:|:------|
| `HaccpTopBar` | ✅ | Gotowy |
| `HaccpStepper` | ✅ | Gotowy |
| `HaccpToggle` | ✅ | W `shared/widgets/dynamic_form/` |
| `HaccpTile` | ✅ | Gotowy |
| `HaccpLongPressButton` | ✅ | Gotowy |
| `HaccpNumPad` | ✅ | Gotowy |
| `SuccessOverlay` | ✅ | Gotowy |
| `OfflineBanner` | ✅ | Gotowy |
| `HaccpEmptyState` | 🚫 | **Brak** — potrzebny w listach bez danych (2.3, 3.5, 4.6, 5.4) |
| `HaccpTimePicker` | 🚫 | **Brak** — spec wymaga dużego pickera godzin. Ekrany GMP używają czegoś innego. |
| `HaccpDatePicker` | 🚫 | **Brak** — spec wymaga dużego pickera dat. Ekrany GMP mogą używać systemowego. |

---

## 🗓️ Plan Sprintów

### Sprint 1: Dashboard Hub + Wspólne Widgety (Priorytet Krytyczny)

> **Cel:** Dashboard Hub działa dynamicznie, brakujące wspólne widgety stworzone.

#### Zadanie 1.1: Dashboard Hub — Dynamiczne dane użytkownika

**Plik:** [dashboard_hub_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/dashboard/screens/dashboard_hub_screen.dart)

**Co zrobić:**

1. Zamienić hardcoded `"Jan Kowalski"` i `"Kuchnia Główna"` na dane z `ref.watch(currentUserProvider)` i `ref.watch(currentZoneProvider)`.
2. Użyj `employee.fullName` i `zone.name` zamiast stringów.
3. Jeśli dane są `null` — pokaż "..." jako placeholder.

**Jak to zrobić:**

```dart
// Przed (linia 14-16):
final userName = "Jan Kowalski";
final venueName = "Kuchnia Główna";

// Po:
final employee = ref.watch(currentUserProvider);
final zone = ref.watch(currentZoneProvider);
final userName = employee?.fullName ?? '...';
final venueName = zone?.name ?? '...';
```

#### Zadanie 1.2: Dashboard Hub — Ukrywanie kafelków HR/Ustawienia wg roli

**Plik:** ten sam `dashboard_hub_screen.dart`

**Co zrobić:**

1. Kafelki "HR & Personel" i "Ustawienia" powinny być widoczne **tylko** dla roli `manager` lub `owner`.
2. Zamień `isVisible: true` na sprawdzanie `employee?.isManager == true`.

**Jak to zrobić:**

```dart
// Na kafelkach HR i Ustawienia:
if (employee?.isManager == true) ...[
  HaccpTile(
    icon: Icons.people,
    label: 'HR & Personel',
    onTap: () => context.push('/hr'),
  ),
  HaccpTile(
    icon: Icons.settings,
    label: 'Ustawienia',
    onTap: () => context.push('/settings'),
  ),
],
```

#### Zadanie 1.3: Dashboard Hub — Dynamiczne badge'y na kafelkach

**Plik:** ten sam + nowy provider w `lib/features/dashboard/providers/dashboard_badges_provider.dart`

**Co zrobić:**

1. Stworzyć provider `dashboardBadgesProvider`, który pobiera:
   - Liczbę alarmów z `measurements` (dla kafelka Monitoring)
   - Liczbę dzisiejszych wpisów GMP z `haccp_logs WHERE category='gmp'`
   - Liczbę niezrobionych checklist GHP
   - Liczbę dzisiejszych odpadów z `waste_records`
   - Liczbę alertów HR (wygasające badania)
2. Przekazać te wartości do parametru `badgeText` w `HaccpTile`.

**Jak to zrobić:**

- Stwórz plik `dashboard_badges_provider.dart`.
- Napisz w nim `FutureProvider<Map<String, String>>` lub `AsyncNotifier`, który robi zapytania do Supabase.
- W `DashboardHubScreen` zrób `ref.watch(dashboardBadgesProvider)` i przekaż wartości.

#### Zadanie 1.4: Widget `HaccpEmptyState`

**Plik do stworzenia:** `lib/core/widgets/empty_state_widget.dart`

**Co zrobić:**

1. Stworzyć widget `HaccpEmptyState` zgodnie ze specyfikacją:
   - Parametry: `headline` (default: "Wszystko Zrobione!"), `subtext` (default: "Brak nowych zadań na dziś."), `buttonLabel` (default: "Wróć do Pulpitu"), `onButtonPressed`.
   - Layout: wyśrodkowany, duża ikona (np. `Icons.coffee` lub `Icons.check_circle`), tekst pod spodem, przycisk akcji.
2. Eksportować z `core/widgets/`.

**Wzorzec:**

```dart
class HaccpEmptyState extends StatelessWidget {
  final String headline;
  final String subtext;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const HaccpEmptyState({
    super.key,
    this.headline = 'Wszystko Zrobione!',
    this.subtext = 'Brak nowych zadań na dziś.',
    this.buttonLabel = 'Wróć do Pulpitu',
    required this.onButtonPressed,
  });
  // ... Column z ikoną, headline, subtext i ElevatedButton
}
```

#### Zadanie 1.5: Widget `HaccpTimePicker`

**Plik do stworzenia:** `lib/core/widgets/haccp_time_picker.dart`

**Co zrobić:**

1. Stworzyć duży, Glove-Friendly Time Picker (min 60dp dotykowy).
2. Może to być wrapper nad `showTimePicker()` z odpowiednim theme'owaniem lub custom widget z dwoma kołami (godziny/minuty).
3. Przycisk aktywujący picker powinien wyświetlać aktualnie wybraną godzinę duży tekstem.

#### Zadanie 1.6: Widget `HaccpDatePicker`

**Plik do stworzenia:** `lib/core/widgets/haccp_date_picker.dart`

**Co zrobić:** Analogicznie do Time Picker — duży przycisk z wybraną datą, otwierający `showDatePicker()` z dark theme.

---

### Sprint 2: M02 Monitoring — Wykres + Alarmy (Priorytet Wysoki)

> **Cel:** Moduł monitoringu temperatur jest w pełni funkcjonalny z wykresami i panelem alarmów.

#### Zadanie 2.1: Temperature Dashboard — Dynamiczny `zone_id`

**Plik:** [temperature_dashboard_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m02_monitoring/screens/temperature_dashboard_screen.dart)

**Co zrobić:**

1. Zamienić hardcoded `const currentZoneId = 'some-zone-id'` na pobieranie z `ref.watch(currentZoneProvider)`.
2. Dodać nawigację po kliknięciu w kartę sensora → `context.push('/monitoring/chart/${sensor.id}')`.
3. Dodać ikona alarmu w TopBar → nawigacja do `/monitoring/alarms`.
4. Dodać pola: interwał ("Co 15 min"), trend (ikona ↑↓→) na karcie sensota.

**Jak to zrobić:**

```dart
final zone = ref.watch(currentZoneProvider);
if (zone == null) return Text('Brak strefy');
final activeSensorsAsync = ref.watch(activeSensorsProvider(zone.id));
```

Owijaj `_SensorCard` w `InkWell` z `onTap: () => context.push(...)`.

#### Zadanie 2.2: Sensor Chart Screen — Implementacja wykresu `fl_chart`

**Plik:** [sensor_chart_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m02_monitoring/screens/sensor_chart_screen.dart)

**Co zrobić (krok po kroku):**

1. Dodać import `fl_chart` (jest już w pubspec.yaml).
2. Stworzyć provider `sensorHistoryProvider(deviceId, timeRange)`, który pobiera dane z tabeli `measurements` WHERE `sensor_id = deviceId` i filtruje po: 24h / 7 dni / 30 dni.
3. Zbudować widget `LineChart` z:
   - Oś X = czas (timestamps z danych).
   - Oś Y = temperatura.
   - Linia progowa: `HorizontalLine` na `y: 10` (czerwona przerywana).
4. Dodać `ChoiceChip` do filtrowania: "24h", "7 dni", "30 dni".
5. Dodać `FloatingActionButton` "Dodaj Adnotację" — otwiera `showModalBottomSheet` z chipami ("Dostawa", "Defrost", "Mycie", "Inne") i polem komentarza.

**Wskazówka dot. fl_chart:**

```dart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: measurements.map((m) => FlSpot(m.timestamp.millisecondsSinceEpoch.toDouble(), m.temperature)).toList(),
      ),
    ],
    extraLinesData: ExtraLinesData(horizontalLines: [
      HorizontalLine(y: 10, color: Colors.red, dashArray: [5, 5]),
    ]),
  ),
)
```

#### Zadanie 2.3: Panel Alarmów — Pełna Implementacja

**Plik:** [alarms_panel_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m02_monitoring/screens/alarms_panel_screen.dart)

**Co zrobić:**

1. Stworzyć provider `alarmsProvider`, który pobiera pomiary z `measurements` gdzie temperatura > 10°C i 3 kolejne odczyty przekraczają normę.
2. Zbudować `TabBar` z dwoma tabami: "Aktywne" i "Historia".
3. Dla każdego alarmu wyświetlić kartę z:
   - Nazwa sensora (bold), temperatura (czerwona, 24sp), czas trwania ("Od: 10:15 (45 min)").
   - Przycisk `HaccpLongPressButton` — "Przyjąłem do wiadomości".
4. Po Long Press → INSERT do `alarm_acknowledgments` (jeśli tabela istnieje) lub do `annotations` z typem "alarm_ack".
5. Użyć `HaccpEmptyState` gdy brak alarmów: "Brak aktywnych alarmów 🎉".

---

### Sprint 3: M04 GHP Dopracowanie + Historia GMP (Priorytet Średni)

> **Cel:** Moduł GHP w pełni nawigacyjny, historie z filtrami.

#### Zadanie 3.1: GHP — Nawigacja do Historii

**Pliki:** [ghp_category_selector_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m04_ghp/screens/ghp_category_selector_screen.dart) + [app_router.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/core/router/app_router.dart)

**Co zrobić:**

1. W `app_router.dart` dodać brakującą trasę:

   ```dart
   GoRoute(
     path: '/ghp/history',
     builder: (context, state) => const GhpHistoryScreen(),
   ),
   ```

2. Dodać import `GhpHistoryScreen` w routerze.
3. W `ghp_category_selector_screen.dart` zmienić placeholder `onTap: () => {}` na `onTap: () => context.push('/ghp/history')`.

#### Zadanie 3.2: GHP Historia — Dodanie Filtrów

**Plik:** [ghp_history_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m04_ghp/screens/ghp_history_screen.dart)

**Co zrobić:**

1. Dodać `Row` z dwoma filtrami nad listą:
   - `DropdownButton` — kategoria: Wszystkie / Personel / Pomieszczenia / Konserwacja / Chemia.
   - `DateRangeButton` — zakres dat (może użyć `showDateRangePicker()`).
2. Filtrować wyniki w providerze lub lokalnie.
3. Na karcie historii dodać chip z kategorią i ikona statusu (✅/❌).

#### Zadanie 3.3: GMP Historia — Dodanie Filtrów

**Plik:** [gmp_history_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m03_gmp/screens/gmp_history_screen.dart)

**Co zrobić:**

1. Dodać `Row` z filtrami analogicznie do GHP:
   - Dropdown: Typ procesu (Pieczenie/Chłodzenie/Dostawa/Wszystkie).
   - DateRange picker.
2. Zaktualizować provider historii GMP, aby przyjmował parametry filtrowania.
3. Na karcie dodać chip procesu i ikona statusu (✅ OK / ⚠️ Ostrzeżenie).

#### Zadanie 3.4: GHP Ekran 4.5 — Rejestr Środków Czystości (poprawka)

**Plik:** Modyfikuj `ghp_checklist_screen.dart` LUB stwórz osobny plik.

**Co zrobić:**

- Specyfikacja mówi, że ekran 4.5 powinien mieć **formularz** (Dropdown + Stepper + Dropdown) **PLUS listę dzisiejszych wpisów** pod spodem. Obecna generyczna checklista nie ma tego layoutu.
- Sprawdź, czy `ChecklistDefinitions.ghpDefinitions['chemicals']` ma odpowiednie pola. Jeśli nie — dodaj je.
- Pod formularzem dodaj `ListView` z dzisiejszymi wpisami kategorii `chemicals`.

---

### Sprint 4: M07 Profil Pracownika + M05/M06 Poprawki (Priorytet Średni)

> **Cel:** Profil pracownika działa w pełni, moduły odpadów i raportów dopracowane.

#### Zadanie 4.1: Profil Pracownika — Pełna Implementacja

**Plik:** [employee_profile_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m07_hr/screens/employee_profile_screen.dart)

**Co zrobić (krok po kroku):**

1. Zmienić `StatelessWidget` na `ConsumerWidget`.
2. Stworzyć provider `employeeDetailProvider(employeeId)`, który pobiera dane z `employees` WHERE `id = employeeId`.
3. Zbudować layout z 4 sekcjami (zgodnie ze specyfikacją UI_description.md Ekran 7.2):
   - **Dane podstawowe:** Card z imieniem, rolą, lokal/strefa.
   - **Badania Sanepid:** Data ważności + miniatura skanu (jeśli jest URL) + przycisk "Aktualizuj badania" (otwiera dialog z DatePicker).
   - **Aktywność:** Ostatnie logowania (lista 5 dat) + liczba checklist w tym tygodniu.
   - **Status:** `HaccpToggle` Aktywny/Nieaktywny — `UPDATE employees SET is_active = ...`.
4. AppBar: `HaccpTopBar` z imieniem pracownika.

#### Zadanie 4.2: Waste Registration — Dynamiczne venue_id

**Plik:** [waste_registration_form_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m05_waste/screens/waste_registration_form_screen.dart)

**Co zrobić:**

1. Zamienić hardcoded `'test_venue_id'` na prawdziwe venue_id z providera.
2. Użyj: `ref.read(currentUserProvider)?.venues.firstOrNull ?? 'default'`.
3. Przekaż to venue_id do `HaccpCameraScreen` i `WasteRepository`.

#### Zadanie 4.3: Waste Historia — Filtry i Podsumowanie

**Plik:** [waste_history_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m05_waste/screens/waste_history_screen.dart)

**Co zrobić:**

1. Dodać filtry: Dropdown "Miesiąc" + Dropdown "Rodzaj odpadu".
2. Dodać wiersz podsumowania: "Łącznie: {n} kg" (suma mas za wybrany okres).
3. Na kartach dodać miniatury zdjęć.

#### Zadanie 4.4: M06 Reports — Podgląd PDF na Web

**Plik:** [reports_panel_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m06_reports/screens/reports_panel_screen.dart) + [pdf_preview_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m06_reports/screens/pdf_preview_screen.dart)

**Co zrobić:**

1. Zamienić SnackBar "Podgląd niedostępny" na prawdziwy podgląd.
2. Na Web: użyć pakietu `printing` — metoda `Printing.layoutPdf()` lub `Printing.sharePdf()` żeby otworzyć PDF w nowej karcie przeglądarki.
3. Alternatywnie: przekonwertuj `Uint8List` na Blob URL i otwórz w iframe.
4. Dodać brakujący typ "Raport Dzienny" do selektora.
5. Dodać przyciski "Pobierz" i "Wyślij e-mail" w `pdf_preview_screen.dart`.

---

### Sprint 5: M08 Ustawienia + UX Polish (Priorytet Niski)

> **Cel:** Moduł ustawień działa w pełni, UX jest spójny z widgetami `HaccpEmptyState` wszędzie.

#### Zadanie 5.1: M08 Ustawienia — Sekcja Sensory Temperatury

**Plik:** [global_settings_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m08_settings/screens/global_settings_screen.dart)

**Co zrobić:**

1. Dodać sekcję "Sensory Temperatury" (brakuje w obecnym kodzie):
   - `SegmentedControl` lub `ChoiceChip` dla interwału: 5 min / 15 min / 60 min.
   - `HaccpStepper` dla progu alarmowego (default: 8°C, range: 0-15, krok 1).
2. Zapisywanie tych ustawień w tabeli `venues` lub nowej tabeli `venue_settings`.
3. Sprawić, aby Toggles "Tryb Ciemny" i "Dźwięki" faktycznie działały (podepnij pod provider).

#### Zadanie 5.2: Logo Upload na Web (File Picker)

**Plik:** ten sam `global_settings_screen.dart`

**Co zrobić:**

1. Na Web nie działa `image_picker`. Użyj pakietu `file_picker` lub HTML input element.
2. Dodaj `file_picker: ^8.0.0` do `pubspec.yaml`.
3. Po wybraniu pliku → kompresja → upload do Supabase Storage `branding`.

#### Zadanie 5.3: Integracja `HaccpEmptyState` w listach

**Pliki:** Wszystkie ekrany z listami

**Co zrobić (lista plików i co zmienić):**

1. `alarms_panel_screen.dart` — gdy brak alarmów, zamiast tekstu pokaż `HaccpEmptyState(headline: "Brak alarmów", subtext: "Wszystkie temperatury w normie")`.
2. `gmp_history_screen.dart` — gdy brak wpisów.
3. `ghp_history_screen.dart` — gdy brak wpisów.
4. `waste_history_screen.dart` — gdy brak wpisów.
5. `waste_panel_screen.dart` — gdy brak ostatnich wpisów.

**Wzorzec:**

```dart
if (items.isEmpty) {
  return HaccpEmptyState(
    headline: 'Brak wpisów',
    subtext: 'Nie ma jeszcze żadnych wpisów w tej kategorii.',
    onButtonPressed: () => context.go('/hub'),
  );
}
```

#### Zadanie 5.4: M05 Camera — File Picker Fallback na Web

**Plik:** [haccp_camera_screen.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m05_waste/screens/haccp_camera_screen.dart)

**Co zrobić:**

1. Na Web, zamiast otwierać kamerę (która nie działa), pokaż przycisk "Wybierz plik".
2. Użyj `file_picker` lub `html.FileUploadInputElement` (import warunkowy).
3. Po wybraniu pliku → upload do Storage jak normalnie.

---

### Sprint 6: Stabilizacja i Testy (Priorytet Krytyczny)

> **Cel:** Testowanie wszystkich poprawionych ekranów, naprawienie błędów.

#### Zadanie 6.1: Przejście po wszystkich modułach

- Uruchom aplikację na Vercel.
- Zaloguj się, przejdź do każdego modułu, wykonaj jedno pełne działanie (np. dodaj wpis GMP, wykonaj checklistę GHP).
- Zanotuj każdy błąd.

#### Zadanie 6.2: Testy nawigacji

- Sprawdź, że wszystkie przyciski "Back" wracają do właściwych ekranów.
- Sprawdź, że `/ghp/history` działa.
- Sprawdź, że tap na kartę sensora przenosi do wykresu.

#### Zadanie 6.3: Testy Glove-Friendly

- Sprawdź, że żaden interaktywny element nie jest mniejszy niż 48×48dp.
- Sprawdź, że przyciski "Zapisz" wymagają Long Press.
- Sprawdź, że nigdzie nie pojawia się klawiatura systemowa (poza polami tekstowymi dla managerów).

---

## 📋 Podsumowanie Priorytetów

| Sprint | Moduły | Wysiłek (dni) | Priorytet |
|:-------|:-------|:------------:|:---------:|
| **S1** | Dashboard Hub + Widgety M09 | 2-3 | 🔴 Krytyczny |
| **S2** | M02 Monitoring (Wykres + Alarmy) | 3-4 | 🔴 Wysoki |
| **S3** | M04 GHP + Historie z filtrami | 2-3 | 🟡 Średni |
| **S4** | M07 Profil + M05/M06 poprawki | 3-4 | 🟡 Średni |
| **S5** | M08 Ustawienia + UX Polish | 2-3 | ✅ Zrobione |
| **S6** | Stabilizacja + Testy | 2 | 🔴 Krytyczny |

**Łączny szacowany czas:** 14-19 dni roboczych (3-4 tygodnie)
