# Sprint 5 — Evaluation: Release Readiness and Error Verification

## 1. Cel sprintu
Ocenić wdrożenie i formalnie zamknąć incydent persistence failure.

## 2. Definition of Done (final)
1. `name/address/logo` zapisują się trwale i są odczytywalne po refresh/relogin.
2. `nip` kontrakt działa (NULL albo 10 cyfr).
3. RLS poprawnie rozdziela uprawnienia manager/owner vs cook.
4. Brak silent failure w logo upload.
5. Testy E2E + SQL smoke zakończone PASS.
6. Logi aplikacyjne i DB nie pokazują nowych błędów krytycznych.

## 3. Weryfikacja logów błędów
| Warstwa | Co sprawdzić |
|---|---|
| Frontend | błędy submit, upload, mapping payload |
| Supabase DB | constraint/RLS violations dla `venues` |
| Supabase Storage | denied/not found/upload errors dla `branding` |

## 4. Kryteria decyzji release
- GO: brak P0/P1, komplet PASS scenariuszy krytycznych.
- NO-GO: dowolny fail w E2E-1/E2E-3/E2E-4 lub niejednoznaczne logi persistence.

## 5. Artefakty zamykające
1. `S5_evaluation_report.md`
2. zaktualizowany release checklist
3. lista residual risks + plan monitoringu 48h po deploy

## 6. Residual risks (jeśli wystąpią)
- niestabilność Storage policy między środowiskami,
- regresja mapowania payload po kolejnych zmianach UI.
