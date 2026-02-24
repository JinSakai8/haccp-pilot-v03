# Sprint 2: Kontrakt danych M08 + Supabase DB

Cel sprintu: ujednolicic specyfikacje i implementacje danych M08 oraz domknac warstwe DB.
Rozmiar sprintu: maly/sredni (1 okno kontekstowe).

## 1. Zakres
1. Ujednolicenie kontraktu dokumentacyjnego:
- M08 zapisuje do `venues` (nie `venue_settings`).
- Doprecyzowanie, ktore pola sa persystentne.
2. Schemat `venues`:
- potwierdzic/dodac kolumny `temp_interval`, `temp_threshold`.
3. RLS dla `venues`:
- SELECT scoped do venue z kontekstu kiosku,
- UPDATE tylko `manager`/`owner`.
4. Walidacje danych lokalu (NIP i progi temperatur).

## 2. Kroki wykonania (dla juniora)
1. Sprawdz aktualny remote schema i porownaj z kontraktem kodu M08.
2. Przygotuj migracje DB (oddzielne, male):
- kolumny + default + check constraints,
- polityki RLS select/update dla `venues`.
3. Zaktualizuj dokumentacje `supabase.md` i `UI_description.md` (sekcja M08), aby byla zgodna z realna tabela.
4. Zweryfikuj, czy zapis ustawien z klienta przechodzi przez RLS dla manager/owner i jest blokowany dla cook.
5. Dodaj test SQL/regresyjny dla policy check.

## 3. Kryteria akceptacji
1. Brak rozjazdu dokumentacja vs implementacja dla M08.
2. `venues.temp_interval` i `venues.temp_threshold` istnieja i maja walidacje.
3. Manager/owner moze zapisac ustawienia; cook/cleaner nie moze.
4. Bledne wartosci (np. threshold poza zakresem) sa odrzucane po stronie DB.

## 4. Testy
1. SQL smoke: valid update (PASS), invalid update (FAIL expected).
2. SQL security: cook update (FAIL expected), manager update (PASS).
3. App manual: zapis ustawien daje sukces i odswiezone dane po reload.

## 5. Wymagane zmiany Supabase
1. `m08_01_venues_settings_columns.sql`
2. `m08_02_venues_rls_update_policy.sql`
3. (opcjonalnie) `m08_03_update_venue_settings_rpc.sql`

## 6. Wyjscie sprintu
1. Stabilny i bezpieczny kontrakt danych M08.
2. Gotowosc do domkniecia UX i produktow w sprincie 3.
