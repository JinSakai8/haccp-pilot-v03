# Code Description - HACCP Pilot (Code Architecture)
## Kiedy Dolaczac Ten Plik Do Konwersacji
- Gdy prosisz o implementacje/refaktor kodu aplikacji.
- Gdy analizujesz flow `screen -> provider -> repository`.
- Gdy weryfikujesz runtime routing i kontrakty modulow.
- Gdy potrzebujesz mapy testow i notatek developerskich.
- Nie dolaczaj do deep-dive ERD/RLS ani do specyfikacji pixel-level UI.

## 1. Zakres Dokumentu
Ten dokument opisuje architekture kodu aplikacji.

Zakres:
- Struktura kodu i konwencje.
- Routing runtime.
- State management, repository contracts i logika modulow.
- Integracje techniczne z perspektywy kodu.
- Testability map i notatki operacyjne.

Poza zakresem:
- Szczegoly ERD/RLS/DDL (patrz `supabase.md`).
- Szczegoly layoutow i specyfikacji UX (patrz `UI_description.md`).
- Big-picture decyzje domenowe (patrz `directives/00_Architecture_Master_Plan.md`).

## 2. Struktura Kodu (`lib/`) i Konwencje
### 2.1 Top-level
- `core/`: infrastruktura aplikacji, router, auth state, serwisy, widgety wspolne.
- `features/`: moduly domenowe M01-M08 + `dashboard`.
- `features/shared/`: wspolne definicje formularzy, dynamic form renderer, shared repositories.

### 2.2 Konwencje warstwowe
- `screens/`: prezentacja i interakcje.
- `providers/`: stan i orkiestracja flow.
- `repositories/`: dostep do danych i mapowanie bledow.
- `models/`: DTO/domain models.
- `config/`: slowniki i kontrakty definicyjne.

### 2.3 Reguly implementacyjne
1. Ekrany nie wywoluja Supabase bezposrednio.
2. Reuzywalne logiki cross-feature trafiaja do `core` lub `shared`.
3. Zmiany kontraktow danych sa prowadzone przez migracje i repository contract updates.

## 3. Routing Runtime (Faktyczny Stan)
Zrodlo prawdy: `lib/core/router/app_router.dart`.

### 3.1 Trasy
- `/`, `/login`, `/zone-select`, `/hub`
- `/monitoring`, `/monitoring/alarms`, `/monitoring/chart/:deviceId`
- `/gmp`, `/gmp/roasting`, `/gmp/cooling`, `/gmp/delivery`, `/gmp/history`
- `/ghp`, `/ghp/checklist`, `/ghp/history`, `/ghp/chemicals`
- `/waste`, `/waste/register`, `/waste/camera`, `/waste/history`
- `/settings`, `/settings/products`
- `/reports`, `/reports/preview/local`, `/reports/preview/ccp2`, `/reports/preview/ccp3`, `/reports/history`, `/reports/drive`
- `/hr`, `/hr/list`, `/hr/add`, `/hr/employee/:id`

### 3.2 Guardy
- Auth guard: niezalogowany user wraca na `/login`.
- Anti-auth loop: zalogowany user nie zostaje na `/` lub `/login`.
- Role guard: `/hr*` i `/settings*` tylko dla manager/owner.

## 4. State Management (Riverpod): Provider Topology
### 4.1 Global providers (`core/providers/auth_provider.dart`)
- `currentUserProvider`: aktualny pracownik.
- `currentZoneProvider`: aktualna strefa pracy.
- `pinLoginProvider`: state machine logowania (idle/loading/success/error/locked).
- `employeeZonesProvider`: lista stref przypisanych do pracownika.

### 4.2 Feature providers
- M02: sensory, strumienie pomiarow, alarmy, akcje ACK/edycji/adnotacji.
- M03/M04/M06/M07/M08: oddzielne provider scopes i notifiery na operacje domenowe.
- Dashboard: dedykowany provider badge dla kart nawigacyjnych.

### 4.3 Wzorzec aktualizacji
- Provider wywoluje repository.
- Po mutacji provider invaliduje tylko dotkniete read paths.
- Komunikaty bledow sa mapowane do komunikatow domenowych wyzej niz warstwa UI atomow.

## 5. Repository Contracts i Error Mapping
| Modul | Repository | Kluczowe kontrakty |
|:--|:--|:--|
| M01 | `core/repositories/auth_repository.dart` | `loginWithPin`, `getZonesForEmployee`, `setKioskContext`, `clearKioskContext` |
| M02 | `m02_monitoring/repositories/measurements_repository.dart` | sensory, historia, tabela 7d, alarm RPC, ACK RPC, edit RPC, annotations insert |
| M03 | `m03_gmp/repositories/gmp_repository.dart` | insert/get history dla `category=gmp`, legacy form-id compatibility w historii |
| M04 | `m04_ghp/repositories/ghp_repository.dart` | insert/get history dla `category=ghp` |
| M05 | `m05_waste/repositories/waste_repository.dart` | insert i historia odpadow |
| M06 | `m06_reports/repositories/reports_repository.dart` | query logow, generacja datasetow raportow, upload/download storage, metadata upsert |
| M07 | `m07_hr/repositories/hr_repository.dart` | create/toggle/update pin/sanepid przez RPC + mapowanie kodow bledow M07 |
| M08 | `m08_settings/repositories/venue_repository.dart` + `shared/repositories/products_repository.dart` | venue settings update + branding upload + produkty CRUD scoped by venue |

Error mapping:
- M07: `M07_PIN_DUPLICATE`, `M07_ZONE_REQUIRED`, `M07_ZONE_NOT_FOUND`, `M07_ZONE_MULTI_VENUE`, `M07_EMPLOYEE_NOT_FOUND`, `M07_PIN_REQUIRED`.
- M08: kategorie `dbConstraint`, `dbRlsDeny`, `storageDenyOrNotFound`, `unknown` mapowane na komunikaty domenowe.

## 6. Moduly M01-M08: Logika Domenowa
### M01 Auth
- PIN hash po stronie klienta.
- Login przez RPC i ustawienie session context.
- Wybor strefy jako warunek poprawnego scope dalszych modulow.

### M02 Monitoring
- Realtime stream po `temperature_logs` scoped do aktywnych sensorow.
- Read model alarmow przez RPC `get_temperature_alarms`.
- ACK i edit temperatur przez dedykowane RPC.
- Edycja 7d wymusza invalidacje wielu read modeli.

### M03 GMP
- Formularze dynamiczne bazowane na definicjach z `shared/config`.
- Zapis do unified `haccp_logs` (`category=gmp`).
- Historia z kompatybilnoscia legacy form IDs.

### M04 GHP
- Checklists i chemikalia w tej samej tabeli logow (`haccp_logs`, `category=ghp`).
- Odczyt i zapis scoped po `zone_id`.

### M05 Waste
- Rejestracja odpadown + foto flow.
- Historia i panel operuja na `waste_records`.

### M06 Reports
- Raporty CCP1/CCP2/CCP3 i waste z miesiecznym lifecycle.
- Archiwizacja: upload do storage + upsert metadata w `generated_reports`.
- Fallback download path i obsluga force regenerate dla preview.

### M07 HR
- Zarzadzanie personelem tylko manager/owner.
- Krytyczne operacje przez RPC.
- Wydzielona klasyfikacja alertow dat sanepidu.

### M08 Settings
- `GlobalSettingsScreen`: venue profile + walidacje + logo upload.
- `ManageProductsScreen`: CRUD produktow z kontekstem venue.
- Brak fallbackowych danych maskujacych problemy runtime.

## 7. Integracje Aplikacyjne (PDF, Storage, Drive)
### PDF
- `core/services/pdf_service.dart` generuje raporty tabelaryczne i formularzowe.
- M06 orchestruje pipeline dataset -> PDF bytes -> preview/upload.

### Storage
- Raporty: bucket `reports`.
- Branding (logo): bucket `branding`.
- Odpady (zdjecia): bucket `waste-docs`.

### Drive
- `core/services/drive_service.dart` obsluguje upload raportow jako funkcje opcjonalna.

## 8. Testability Map
| Poziom | Lokalizacja | Zakres |
|:--|:--|:--|
| Unit | `test/features/**` | reguly domenowe, mapowania, kontrakty requestow |
| Widget | `test/features/**` | zachowania ekranow, stany i interakcje |
| Integration/contract | `test/db_consistency_test.dart`, repo tests | spojnosc danych i kontrakty repozytorium |
| SQL smoke | `supabase/*_smoke_tests.sql` | walidacja kontraktow DB po migracjach |

Minimalny scope regresji przy zmianie kontraktu:
1. tests modułu dotknietego.
2. tests raportowania jesli zmiana dotyka logow/storage.
3. smoke SQL jesli zmiana dotyka RLS/RPC.

## 9. Operational Notes dla Dewelopera
1. Zrodla prawdy:
- runtime routes: `lib/core/router/app_router.dart`
- provider topology: `lib/core/providers`, `lib/features/*/providers`
- kontrakty DB: `supabase.md` + `supabase/migrations/*`

2. Lokalne ograniczenia:
- Czesci testow PDF moze miec ograniczenia srodowiska renderera.
- Debug logs raportow sa kontrolowane flaga `HACCP_REPORTS_DEBUG`.

3. Rekomendowany workflow przy zmianach:
- Aktualizacja kodu -> testy modulu -> aktualizacja odpowiedniego dokumentu warstwy.
- Bez dopisywania SQL/UI detali do `Code_description.MD`.

## 10. Local Toolchain (Windows)
- Flutter SDK path: `C:\scr\flutter\bin`
- Preferred command form: `C:\scr\flutter\bin\flutter.bat <args>`

