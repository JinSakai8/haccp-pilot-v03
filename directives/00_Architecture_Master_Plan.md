# 00 - Architecture Master Plan: HACCP Pilot v03-10

> Autor: Lead System Architect (AI)  
> Data aktualizacji: 2026-02-20  
> Status: ACTIVE - Sprint 6 (Documentation Refresh) COMPLETED  
> Horyzont: 6 sprintow (5 naprawczych + 1 dokumentacyjny)

---

## 1. Cel dokumentu

Ten dokument opisuje aktualna architekture aplikacji oraz plan naprawczy usuwajacy dryf architektoniczny:

1. naruszenia warstw dostepu do danych,
2. duplikacje widgetow formularzy,
3. niespojne routing/provider lifecycle,
4. niesprawne lub nieaktualne testy,
5. niski poziom enforce quality/lint/logging.

---

## 2. Aktualna architektura (stan kodu)

### 2.1 Struktura projektu

- `lib/core/*`: uslugi wspolne, modele globalne, routing, motyw, widgety globalne.
- `lib/features/*`: moduly domenowe (M01-M08 + dashboard + shared).
- `lib/features/shared/*`: wspolne definicje formularzy i czesc komponentow dynamic form.

To jest praktycznie Feature-First z centralnym `core`.

### 2.2 Warstwy i przeplyw

Docelowy przeplyw:

`Screen -> Provider -> Repository -> SupabaseService -> Supabase`

Aktualnie ten model jest wdrozony w wiekszosci modulow, ale historycznie byly wyjatki (Sprint 1 je usuwa).

### 2.3 State management

- Riverpod + code generation (`@riverpod`, pliki `*.g.dart`).
- Core state: auth/current zone/connectivity.
- Feature state: per modul, glownie async providers/notifiers.

### 2.4 Routing

- Centralny router: `lib/core/router/app_router.dart`.
- Guardy auth i role-based (`/hr`, `/settings`).
- Trasy aplikacji sa oparte o stale `RouteNames`.

### 2.5 Integracja Supabase

- Centralna inicjalizacja: `lib/core/services/supabase_service.dart`.
- Repozytoria domenowe korzystaja z `SupabaseService.client`.
- Storage i raporty sa obslugiwane przez serwisy/repozytoria M05/M06.

---

## 3. Decyzje architektoniczne (obowiazujace)

1. **Single access point do Supabase:** tylko `SupabaseService` udostepnia klienta.
2. **Brak bezposrednich wywolan Supabase w UI:** ekrany i widgety nie moga wykonywac zapytan do DB/Storage.
3. **Repository boundary:** logika dostepu do danych tylko w repository/service warstwie.
4. **Riverpod contract:** global state bez `autoDispose`, feature state domyslnie `autoDispose` (chyba ze uzasadnione inaczej).
5. **Feature-First:** kod domenowy pozostaje w `features/<modul>/...`.
6. **Shared UI policy:** jeden canonical widget dla jednego typu komponentu.

---

## 4. Znane odchylenia od architektury (baseline 2026-02-20)

1. Bezposrednie uzycia `Supabase.instance.client` poza `SupabaseService` (czesciowo naprawione w Sprint 1).
2. Duplikacje komponentow dynamic form vs core widgets.
3. Niespojnosci tras/stalych tras.
4. Testy z nieaktualnymi importami i historycznymi zalozeniami.
5. Nadmiar `print/debugPrint` w logice domenowej.

---

## 5. Plan naprawczy - 6 sprintow

## Sprint 1 - Data Layer Hardening (COMPLETED)

Cel:
- usunac bezposrednie odwolania `Supabase.instance.client` poza `SupabaseService`.

Zakres:
- providers/serwisy/repozytoria naruszajace kontrakt.

Status:
- [x] `dashboard_badges_provider`: przejscie na `SupabaseService.client`
- [x] `pdf_service`: przejscie na `SupabaseService.storage`
- [x] `products_repository`: repo oparte o `SupabaseService.client`
- [x] finalna walidacja grep (naruszenia tylko w `supabase_service.dart`)

Definition of Done:
- grep nie pokazuje naruszen poza `supabase_service.dart`.

## Sprint 2 - Widget Consolidation (COMPLETED)

Cel:
- usunac duplikaty widgetow i utrzymac jeden canonical zestaw komponentow.

Zakres:
- `core/widgets/*` vs `features/shared/widgets/dynamic_form/*`.

Status:
- [x] usuniete duplikaty `HaccpDatePicker`, `HaccpTimePicker`, `HaccpStepper` w `features/shared/widgets/dynamic_form`
- [x] `DynamicFormRenderer` przepiety na komponenty z `core/widgets`
- [x] `HaccpToggle`, `HaccpTextInput`, `HaccpNumPadInput` przeniesione do `core/widgets` i podmienione importy
- [x] `HaccpDropdown` pozostawiony w `features/shared` (zaleznosc od `productsProvider`)

Definition of Done:
- brak zdublowanych implementacji dla tych samych komponentow.

## Sprint 3 - Routing and Provider Lifecycle Alignment (COMPLETED)

Cel:
- ujednolicic routing i lifecycle providerow.

Zakres:
- stale route names, guardy roli, spojnosc `autoDispose`.

Status:
- [x] rozszerzenie `RouteNames` o pelny katalog tras i helpery tras parametryzowanych
- [x] `app_router.dart` przepiety na stale tras + guard dla `/settings` i `/hr`
- [x] usuniete literalne `context.go/push('/...')` w ekranach feature

Definition of Done:
- trasy spiete w stale i guardy pokrywaja wszystkie sciezki restricted.

## Sprint 4 - Test Repair and Quality Gate (COMPLETED)

Cel:
- przywrocic wiarygodna suite testowa i statyczna jakosc.

Zakres:
- naprawa testow, aktualizacja importow, usuniecie testow inspekcyjnych.

Status:
- [x] naprawiony `test/features/m02_monitoring/m02_ui_test.dart` pod aktualne modele/providery
- [x] zastapiony sztucznie failujacy `test/db_consistency_test.dart` testami regresji kontraktow tabel
- [x] zaktualizowany `test/widget_test.dart` (smoke test aplikacji zamiast legacy counter)
- [x] `flutter test` przechodzi (z 2 celowo pominietymi testami PDF zaleznymi od ograniczen runtime Syncfusion)

Definition of Done:
- testy przechodza, brak sztucznie failujacych testow.

## Sprint 5 - Production Hardening and Cleanup (COMPLETED)

Cel:
- podniesc maintainability i stabilnosc.

Zakres:
- logging policy, handling errors, cleanup TODO/FIXME, ograniczenie noise debug.

Definition of Done:
- ustandaryzowany logging i czystsza warstwa domenowa.

Status:
- [x] dodany centralny `AppLogger` i przepiecie logowania w serwisach/repozytoriach
- [x] usuniete bezposrednie `print/debugPrint` z warstwy domenowej (poza implementacja `AppLogger`)
- [x] cleanup komentarzy TODO/FIXME w kodzie objetych zmianami
- [x] walidacja: `flutter analyze` (zmienione pliki) oraz `flutter test` przechodza

## Sprint 6 - Documentation Refresh (COMPLETED)

Cel:
- zsynchronizowac dokumentacje ze stanem kodu po Sprintach 1-5.

Pliki:
- `Code_description.MD`
- `supabase.md`
- `UI_description.md`

Definition of Done:
- dokumentacja odzwierciedla realna strukture, kontrakty danych i katalog widgetow.

Status:
- [x] zaktualizowany `Code_description.MD` (architektura, moduly, serwisy, tooling)
- [x] zaktualizowany `supabase.md` (realny kontrakt tabel/RPC/Storage)
- [x] zaktualizowany `UI_description.md` (aktualna mapa ekranow i katalog widgetow)

---

## 6. Ryzyka i zaleznosci

1. Brak lokalnego `flutter` CLI utrudnia automatyczna walidacje (`flutter analyze`, testy).
2. Zmiany widgetow w Sprint 2 moga wymusic poprawki formularzy M03/M04/M05.
3. Sprint 4 wymaga aktualnego i stabilnego schematu DB/RPC po stronie Supabase.

---

## 7. Kryteria akceptacji programu naprawczego

1. Warstwy sa egzekwowane przez kod i review checklist.
2. Testy sa aktualne i przechodza.
3. Brak duplikatow kluczowych komponentow UI.
4. Dokumentacja techniczna odpowiada implementacji 1:1.
