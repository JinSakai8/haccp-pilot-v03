# 🔴 Security Audit Report — HACCP Pilot v03

# Raport z Testu Penetracyjnego

> **Audytor:** AI Security Review (Directive 10a)
> **Data:** 2026-02-14
> **Scope:** Cały codebase Flutter + konfiguracja Supabase
> **Klasyfikacja:** Wewnętrzny — Poufny

---

## Podsumowanie Wykonawcze

Przeprowadzono audyt bezpieczeństwa aplikacji HACCP Pilot obejmujący:

- Ochronę przed brute-force na ekranie PIN
- Bezpieczeństwo kluczy i credentials
- Polityki Row Level Security (RLS)
- Mechanizm Audit Log

**Znaleziono 7 podatności**, w tym **3 krytyczne**, **2 wysokie** i **2 średnie**.

---

## Wyniki Szczegółowe

### 🔴 SEC-01: Brak `.gitignore` — Klucze Google wystawione na wyciek (KRYTYCZNY)

| Atrybut | Wartość |
|:---|:---|
| **Severity** | 🔴 CRITICAL |
| **Status** | OTWARTA |
| **Plik** | `assets/credentials.json` |
| **Wektor ataku** | Wyciek na GitHub / dysk współdzielony |

**Opis:** Plik `credentials.json` zawiera pełny klucz prywatny Google Service Account (`private_key`). W repozytorium **nie istnieje plik `.gitignore`**. Oznacza to, że:

1. Każdy `git push` wyśle klucz prywatny na GitHub.
2. Jeśli repozytorium jest publiczne — klucz jest widoczny dla całego świata.
3. Nawet po usunięciu pliku, klucz **pozostaje w historii Git** (wymaga `git filter-branch` lub BFG Repo-Cleaner).

> [!CAUTION]
> Z konwersacji `a161753e` (Pushing Code to GitHub) wynika, że kod **był już pushowany na GitHub**. Klucz prywatny mógł już wyciec. **Wymaga natychmiastowej rotacji klucza w Google Cloud Console.**

**Dowód:**

```json
// assets/credentials.json — Linia 5
"private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADA..."
```

**Remediation:**

1. ✅ Utwórz `.gitignore` z wpisami: `assets/credentials.json`, `.env`, `*.jks`
2. ✅ Rotuj klucz w Google Cloud Console → IAM → Service Accounts
3. ✅ Uruchom `git filter-branch` lub BFG aby usunąć klucz z historii Git
4. 🔒 Rozważ przeniesienie `credentials.json` do katalogu poza repozytorium

---

### 🔴 SEC-02: Brak ochrony przed Brute-Force na PIN (KRYTYCZNY)

| Atrybut | Wartość |
|:---|:---|
| **Severity** | 🔴 CRITICAL |
| **Status** | OTWARTA |
| **Plik** | [auth_provider.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/core/providers/auth_provider.dart) |
| **Wektor ataku** | Fizyczny dostęp do tabletu (Kiosk Mode) |

**Opis:** Ekran PinPadScreen i `PinLoginNotifier` **nie implementują żadnego mechanizmu blokady** po nieudanych próbach logowania. Atakujący z fizycznym dostępem do tabletu może:

1. Wpisywać PIN **nieskończenie wiele razy** bez żadnych ograniczeń.
2. PIN to tylko **4 cyfry** → 10⁴ = **10 000 kombinacji**.
3. Przy auto-submit (4 cyfry) i ~3 sekundach na próbę → **~8.3 godziny** do złamania dowolnego PIN.
4. Brak logowania nieudanych prób — administrator nie dowie się o ataku.

**Dowód:**

```dart
// auth_provider.dart — login() — Linia 45-72
// Brak: counter prób, timer lockout, limit prób, logowanie
Future<Employee?> login(String pin) async {
  state = LoginStatus.loading;
  // ... bezpośrednie zapytanie do DB bez żadnych ograniczeń
}
```

**Remediation:**

1. Dodaj counter `_failedAttempts` w `PinLoginNotifier`
2. Po **5 nieudanych próbach** → blokada na **30 sekund** (wyświetl timer)
3. Po **10 próbach** → blokada na **5 minut**
4. Po **20 próbach** → blokada na **30 minut** + powiadomienie managera
5. Loguj każdą nieudaną próbę do tabeli `auth_attempts` w Supabase

---

### 🔴 SEC-03: `pin_hash` widoczny dla każdego zalogowanego użytkownika (KRYTYCZNY)

| Atrybut | Wartość |
|:---|:---|
| **Severity** | 🔴 CRITICAL |
| **Status** | OTWARTA |
| **Pliki** | [auth_repository.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/core/repositories/auth_repository.dart), [hr_repository.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m07_hr/repositories/hr_repository.dart), [employee.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/core/models/employee.dart) |
| **Wektor ataku** | DevTools / Interceptor proxy |

**Opis:** Zapytania do `employees` używają `.select()` **bez filtrowania kolumn**, co zwraca **wszystkie pola**, w tym `pin_hash`.

**Pytanie z briefu: „Czy pracownik (role: employee) może za pomocą narzędzi deweloperskich zobaczyć PIN-y innych osób?"**

**Odpowiedź: TAK — to jest realne zagrożenie.**

Ścieżka ataku:

1. Kucharz loguje się normalnie swoim PIN-em.
2. Otwiera narzędzia deweloperskie (Flutter Inspector / Dart DevTools) lub proxy (mitmproxy/Charles).
3. `hr_repository.getEmployees()` zwraca WSZYSTKIE rekordy z kolumną `pin_hash`.
4. Mimo że PIN jest hashowany (SHA-256), hash jest **deterministyczny** — atakujący może zbudować tabelę tęczową: `sha256("0000")`, `sha256("0001")`, ..., `sha256("9999")` — **10 000 hashy w <1 sekundzie**.
5. Porównuje hashe → zna PIN każdego pracownika.

> [!WARNING]
> SHA-256 bez soli (salt) sprawia, że hashowanie PIN-u 4-cyfrowego jest praktycznie bezwartościowe. 10K możliwości = instant brute-force.

**Dowód:**

```dart
// auth_repository.dart — Linia 19-24
.from('employees')
.select()  // ← Zwraca WSZYSTKO, w tym pin_hash!
.eq('pin_hash', hashedPin)

// hr_repository.dart — Linia 31-34
.from('employees')
.select()  // ← Zwraca WSZYSTKO, w tym pin_hash!
.order('full_name', ascending: true);

// employee.dart — Linia 22
pinHash: json['pin_hash'] as String, // ← Model przechowuje hash
```

**Remediation:**

1. **Frontend**: Zmień `.select()` na `.select('id, full_name, role, is_active, sanepid_expiry')` — NIGDY nie pobieraj `pin_hash`.
2. **Backend (RLS)**: Utwórz politykę RLS na kolumnie `pin_hash` — pracownicy NIGDY nie powinni widzieć tej kolumny.
3. **Model**: Usuń pole `pinHash` z klasy `Employee`. Logowanie powinno zwracać jedynie potwierdzenie sukcesu.
4. **Hashing**: Dodaj **losową sól (salt)** per pracownik: `sha256(salt + pin)`. Przechowuj sól w osobnej kolumnie.

---

### 🟠 SEC-04: Brak RLS na tabeli `employees` (WYSOKI)

| Atrybut | Wartość |
|:---|:---|
| **Severity** | 🟠 HIGH |
| **Status** | OTWARTA |
| **Lokalizacja** | Supabase Dashboard → `employees` table |
| **Wektor ataku** | Supabase anon key + REST API |

**Opis:** W pliku `01_db_schema_auth.md` **deklaruje się** RLS:
> *„Tylko role 'owner' i 'manager' mogą wykonywać INSERT/UPDATE w employees."*

Ale **nie ma skryptu SQL** który to implementuje. Jedyne istniejące polityki RLS dotyczą tabel `sensors` i `temperature_logs` (plik `05_M02_Schema.sql`).

Ktoś z kluczem `anon` (widocznym w `.env`) może:

1. Wywołać `POST /rest/v1/employees` i stworzyć nowego użytkownika z rolą `owner`.
2. Odczytać wszystkie rekordy (w tym `pin_hash`) przez `GET /rest/v1/employees`.

**Remediation:**

```sql
-- Do uruchomienia w Supabase SQL Editor
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Odczyt: wszyscy zalogowani, ale BEZ kolumny pin_hash
CREATE POLICY "employees_read" ON employees
FOR SELECT USING (auth.role() = 'authenticated');

-- Zapis: tylko owner/manager (wymaga custom claim lub check)
CREATE POLICY "employees_write" ON employees
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Kolumna pin_hash: ukryta przez widok (VIEW)  
CREATE VIEW employees_safe AS
SELECT id, full_name, role, is_active, sanepid_expiry
FROM employees;
```

---

### 🟠 SEC-05: Brak Audit Log — Kto stworzył wpis? (WYSOKI)

| Atrybut | Wartość |
|:---|:---|
| **Severity** | 🟠 HIGH |
| **Status** | OTWARTA |
| **Lokalizacja** | Wszystkie tabele (gmp_logs, ghp_logs, waste_records, employees) |
| **Wymaganie** | HACCP / Sanepid audit trail |

**Opis:** **Żadna tabela** nie posiada pól audytowych. Brak odpowiedzi na pytania:

- Kto stworzył ten wpis?
- Kto go ostatnio zmienił?
- Kiedy dokładnie?

W modelu `WasteRecord` istnieje pole `user_id`, ale jest to jedyny przypadek. Tabele `gmp_logs`, `ghp_logs`, `employees` — brak `created_by`.

Dla systemu HACCP jest to **wymaganie regulacyjne** — każdy wpis musi mieć ścieżkę audytu (Audit Trail) dla kontroli Sanepidu.

**Remediation:**

```sql
-- Dodaj kolumny do KAŻDEJ tabeli operacyjnej
ALTER TABLE gmp_logs 
  ADD COLUMN created_by UUID REFERENCES employees(id),
  ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN updated_by UUID REFERENCES employees(id),
  ADD COLUMN updated_at TIMESTAMPTZ;

ALTER TABLE ghp_logs 
  ADD COLUMN created_by UUID REFERENCES employees(id),
  ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN updated_by UUID REFERENCES employees(id),
  ADD COLUMN updated_at TIMESTAMPTZ;

-- Trigger automatyczny na updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON gmp_logs
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

### 🟡 SEC-06: Stack Trace eksponowany w produkcji (ŚREDNI)

| Atrybut | Wartość |
|:---|:---|
| **Severity** | 🟡 MEDIUM |
| **Status** | OTWARTA |
| **Plik** | [main.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/main.dart) — Linia 53-63 |

**Opis:** Klasa `ErrorApp` wyświetla **pełny stack trace** na ekranie w przypadku błędu inicjalizacji. W produkcji ujawnia to wewnętrzną strukturę aplikacji atakującemu.

**Remediation:** Wyświetlaj stack trace tylko w trybie debug:

```dart
if (kDebugMode && stackTrace != null) ...[
  // Stack trace
]
```

---

### 🟡 SEC-07: Naruszenie architektury — bezpośredni import Supabase (ŚREDNI)

| Atrybut | Wartość |
|:---|:---|
| **Severity** | 🟡 MEDIUM |
| **Status** | OTWARTA |
| **Plik** | [hr_repository.dart](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/lib/features/m07_hr/repositories/hr_repository.dart) — Linia 3 |

**Opis:** `HrRepository` importuje `package:supabase_flutter/supabase_flutter.dart` bezpośrednio, łamiąc zasadę z Architecture Master Plan:
> *„Repozytoria NIGDY nie importują `supabase_flutter` bezpośrednio — zawsze przez SupabaseService."*

Import jest niewykorzystywany (klasa używa `SupabaseService.client`), ale tworzy niepotrzebną zależność.

---

## Macierz Ryzyka

```
     IMPACT
       ▲
  HIGH │ SEC-04  │ SEC-01, SEC-02, SEC-03
       │         │
  MED  │         │ SEC-05
       │         │
  LOW  │ SEC-07  │ SEC-06
       │─────────┼───────────────────────►
       │   LOW   │       HIGH
                  LIKELIHOOD
```

## Priorytet Napraw

| # | Podatność | Priorytet | Wysiłek |
|:--|:----------|:----------|:--------|
| 1 | SEC-01: `.gitignore` + Rotacja kluczy | 🔴 NATYCHMIAST | 15 min |
| 2 | SEC-03: Ukrycie `pin_hash` (select + model) | 🔴 NATYCHMIAST | 30 min |
| 3 | SEC-02: Brute-force lockout | 🔴 DZISIAJ | 1-2h |
| 4 | SEC-04: RLS na `employees` | 🟠 DZISIAJ | 30 min |
| 5 | SEC-05: Audit Trail (SQL migration) | 🟠 TEN TYDZIEŃ | 2h |
| 6 | SEC-06: Stack trace w produkcji | 🟡 TEN TYDZIEŃ | 5 min |
| 7 | SEC-07: Architektura import fix | 🟡 PRZY OKAZJI | 2 min |

---

## Rekomendacje Dodatkowe

1. **PIN Salting**: Zmień hashing z `sha256(pin)` na `sha256(unique_salt + pin)` — uniemożliwi tabelę tęczową.
2. **Supabase Auth**: Rozważ przejście z custom PIN auth na Supabase Auth z numerem telefonu (Magic Link / OTP) — lepsze bezpieczeństwo na dłuższą metę.
3. **Testy bezpieczeństwa**: Dodaj unit testy weryfikujące lockout i filtry kolumn.
4. **Monitoring**: Dodaj alerting na nietypowe wzorce logowania (np. >10 błędnych PIN-ów w 5 min).
