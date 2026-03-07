# Sprint 2-3 (CCP-3 Query Fix + DB Hardening)

## Sprint 2: Poprawa odczytu CCP-3 (1-1.5 dnia)

### Cel
CCP-3 czyta wyłącznie właściwe logi chłodzenia dla aktywnego kontekstu użytkownika.

### Zadania
- [x] S2.1 Rozszerzyć repo `getCoolingLogs(...)` o `zoneId` i `venueId`.
- [x] S2.2 Przekazać kontekst z providera do repo.
- [x] S2.3 Reguła filtrowania:
  - najpierw `zone_id`,
  - fallback `venue_id` jeśli brak `zone_id`.
- [x] S2.4 Dodać testy repo na komplet filtrów:
  - `category='gmp'`,
  - `form_id='food_cooling'`,
  - zakres dat,
  - `zone_id`/`venue_id`.
- [x] S2.5 Zredukować logi debug po walidacji.

### Kryteria akceptacji
- [ ] Dwie strefy, ten sam dzień: CCP-3 zwraca tylko dane aktywnej strefy.
- [ ] Brak regresji generowania PDF.

---

## Sprint 3: Hardenowanie DB (RLS + indeksy + constraints) (1.5-2 dni)

### Cel
Przenieść izolację danych do warstwy bazy, nie tylko do kodu aplikacji.

### Zadania
- [x] S3.1 Migracja RLS dla `haccp_logs`: odejście od `USING (true)` / `CHECK (true)`.
- [x] S3.2 Polityki SELECT/INSERT zgodne z modelem multi-tenant (`venue_id`) i kiosk auth.
- [x] S3.3 Dodać indeksy:
  - `(category, form_id, created_at)`,
  - `(zone_id, created_at)`,
  - `(venue_id, created_at)`.
- [x] S3.4 Dodać constraints:
  - `category` in (`gmp`, `ghp`),
  - `form_id` w zatwierdzonym słowniku.
- [ ] S3.5 Testy negatywne RLS (brak odczytu danych z innego venue).

### Kryteria akceptacji
- [ ] GMP/CCP-3 działają na nowych politykach.
- [ ] Testy negatywne RLS przechodzą.

### Ryzyka
- Restrukcyjne RLS może przerwać flow anonimowy (`signInAnonymously`).

### Mitigacja
- Wdrożenie w trybie etapowym + szybki rollback SQL.
