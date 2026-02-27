# Integration Sprint 3 - Smoke Checklist (Cross-Module)

## Cel
Potwierdzic stabilnosc zapisu M04 po hotfixie DB oraz regresje M06 dla danych GHP (`ghp_*` + legacy).

## Scenariusze manualne
1. Zaloguj sie jako manager i wybierz strefe.
2. M04 -> Checklista Personel:
   - wypelnij pola, zapisz wpis.
   - oczekiwane: brak bledu `23514`, wpis widoczny w historii.
3. M04 -> Checklista Pomieszczenia:
   - wybierz pomieszczenie, wypelnij pola, zapisz wpis.
   - oczekiwane: brak bledu `23514`, wpis widoczny w historii.
4. M06 -> Raport GHP za biezacy miesiac:
   - oczekiwane: raport generuje sie poprawnie, bez regresji flow archiwizacji.

## Scenariusze SQL (smoke)
1. Insert `category='ghp', form_id='ghp_personnel'` -> PASS.
2. Insert `category='ghp', form_id='ghp_rooms'` -> PASS.
3. Insert `category='ghp', form_id='personnel'` -> PASS (legacy).
4. Insert `category='ghp', form_id='bad_form_id'` -> FAIL (constraint aktywny).

## Kryteria zaliczenia sprintu
1. Brak bledu check-constraint przy zapisie M04 Personel/Pomieszczenia.
2. M06 raport GHP pozostaje kompatybilny z kanonicznym i legacy `form_id`.
3. Testy automatyczne M06/M04 przechodza.
