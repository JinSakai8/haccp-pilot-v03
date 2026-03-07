# Sprint 4: ACK Interaction + Reactivity

## Cel
Ustabilizowac potwierdzanie alarmu (ACK) i reaktywnosc UI.

## Zakres
- ACK przez `alarmActionProvider.notifier.acknowledge(logId)`.
- Local state `pending` per row (blokada duplikatow).
- Podczas ACK:
  - karta ma stan loading/disabled
  - brak mozliwosci ponownego triggera
- Po ACK:
  - invalidacja `alarmsProvider` (aktywny + historia)
  - rekord znika z aktywnych i pojawia sie w historii po refreshu

## Kryteria akceptacji
- Long press <1s: brak ACK.
- Long press >=1s: pojedynczy ACK.
- Brak wielokrotnych wywolan przy szybkim klikaniu.
