# Incident Recovery: Anonymous Auth Disabled

## Objaw
- Aplikacja na Vercel pokazuje ekran inicjalizacji z bledem:
  - `anonymous_provider_disabled`
- Dodatkowo przy pracy kiosk mogl wystepowac:
  - `auth.uid() is null`

## Przyczyna
- W Supabase Auth wylaczony provider **Anonymous Sign-Ins**.
- Model kiosk + RLS wymaga aktywnej sesji anonimowej.

## Szybkie przywrocenie dzialania (15 min)
1. Wejdz do Supabase Dashboard projektu `HACCP_Pilot`.
2. Otworz `Authentication -> Providers`.
3. Wlacz `Anonymous Sign-Ins`.
4. Zapisz ustawienia.
5. Odswiez aplikacje na Vercel (hard refresh).

## Walidacja po naprawie
1. Login PIN dziala.
2. Ekran wyboru strefy laduje sie.
3. Wybor strefy nie zwraca bledu RPC.
4. Zapis `food_cooling` przechodzi i widac wpis w historii.
5. CCP-3 pokazuje wpis dla aktywnej strefy.

## Plan zapobiegawczy
1. Dodaj punkt kontrolny do release checklist:
   - `Anonymous Sign-Ins` wlaczone.
2. Przed canary uruchamiaj smoke test:
   - login -> strefa -> zapis GMP -> odczyt historii.
3. Trzymaj w dokumentacji jeden runbook incydentowy (ten plik).
