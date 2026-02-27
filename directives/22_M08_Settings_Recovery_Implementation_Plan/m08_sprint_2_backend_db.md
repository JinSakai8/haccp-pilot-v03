# Sprint 2 — Backend/DB: Contract and Storage Hardening

## 1. Cel sprintu
Naprawić warstwę DB/Storage tak, aby backend akceptował poprawny payload i jednoznacznie raportował błędy.

## 2. Zakres
- `venues`: walidacje i kontrakt zapisu (bez degradacji constraintów biznesowych).
- RLS `venues`: potwierdzenie update scope manager/owner.
- Storage `branding`: bucket + policy + ścieżka zapisu + odczyt logo.

## 3. Zadania wykonawcze
1. Potwierdzić, że `nip` w kontrakcie może być `NULL`, a nie pusty string.
2. Zweryfikować i (jeśli brak) dodać migracje/polityki dla `storage.objects` bucket `branding`.
3. Zdefiniować jednolity format błędu backendowego:
- constraint violation,
- RLS violation,
- storage denied/not found.
4. Uzupełnić SQL smoke test:
- pozytywny update `venues` (name/address/logo_url),
- negatywny przypadek invalid `nip`,
- deny dla cook,
- upload logo policy pass/fail.

## 4. Interfejsy/kontrakty do utrzymania
| Kontrakt | Wymaganie |
|---|---|
| `venues.nip` | `NULL` albo 10 cyfr |
| `venues.logo_url` | pełny URL publiczny lub jawnie uzgodniona ścieżka bucketowa |
| RLS update venues | tylko manager/owner + kiosk scope |
| Storage branding | write/read w scope tenantowym zgodnie z polityką |

## 5. Testy DB/Storage (obowiązkowe)
1. SQL: valid update + readback.
2. SQL: invalid `nip` => check violation.
3. SQL: cook update => 0 rows / RLS deny.
4. Storage smoke: upload logo + odczyt URL.

## 6. Definition of Done Sprintu 2
- Backend kontrakt jest jawny i udokumentowany.
- Storage `branding` ma potwierdzony mechanizm zapisu.
- Smoke SQL przechodzi na środowisku testowym.
