# Directive 10a: Security Audit & Hardening

> **Status:** IMPLEMENTED / PENDING VERIFICATION
> **Data:** 2026-02-14
> **Raport:** [Security_Audit_Report.md](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/directives/Security_Audit_Report.md)
> **SQL:** [10a_security_hardening.sql](file:///c:/Users/HP/OneDrive%20-%20flowsforge.com/Projekty/HACCP%20Mięso%20i%20Piana/Up%20to%20date/directives/10a_security_hardening.sql)

## Cel

Przeprowadzenie testu penetracyjnego (Pentest) aplikacji HACCP Pilot v03. Identyfikacja i naprawa podatności bezpieczeństwa przed wdrożeniem produkcyjnym.

## Status Napraw

1. ✅ **Brute-force Protection**: Zaimplementowano logikę blokady w `AuthProvider` (5 prób = 30s, 10 prób = 5min). Dodano timer na ekranie PIN Pad.
2. ✅ **Credential Leak**: Dodano `.gitignore` z wykluczeniem `credentials.json` i `.env`.
3. ✅ **Data Exposure**: Usunięto `pin_hash` z modelu `Employee` i zapytań `.select()` w repozytoriach.
4. ✅ **Audit Log & RLS**: Wygenerowano skrypt SQL dodający polityki RLS i kolumny `created_by`/`updated_by`.

## Wymagane Działania Manualne

1. **SQL Migration**: Uruchom skrypt `10a_security_hardening.sql` w Supabase SQL Editor.
2. **Credential Rotation**: Wygeneruj nowe klucze Service Account w Google Cloud Console i podmień `credentials.json`.
3. **Git History Cleanup**: (Opcjonalnie) Wyczyść historię Gita z poprzednich kluczy.
