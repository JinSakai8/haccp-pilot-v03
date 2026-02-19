# Vercel Troubleshooting Guide (Flutter Web)

Ten dokument zawiera historię problemów napotkanych podczas deployu aplikacji HACCP Pilot na Vercel oraz zastosowane rozwiązania. Służy jako baza wiedzy na przyszłość.

## Ostatnie Problemy (Sprint 4/5 - Luty 2026)

### 1. `Uint8List?` vs `Uint8List`

**Błąd:**

```
Error: The argument type 'Uint8List?' can't be assigned to the parameter type 'Uint8List'.
final file = XFile.fromData(bytes, ...);
```

**Przyczyna:** Metoda `XFile.fromData` nie akceptuje wartości null, a zmienna `bytes` była typu nullable.
**Rozwiązanie:** Dodano sprawdzenie null-safety:

```dart
if (bytes != null) {
  final file = XFile.fromData(bytes, ...);
}
```

### 2. Przestarzała metoda `.is_()` w Postgrest

**Błąd:**

```
Error: The method 'is_' isn't defined for the type 'PostgrestFilterBuilder'.
query = query.is_('venue_id', null);
```

**Przyczyna:** Nowsza wersja biblioteki `supabase_flutter` (Postgrest v2+) usunęła metodę `.is_()`.
**Rozwiązanie:** Zastąpiono składnią `.filter()`:

```dart
query = query.filter('venue_id', 'is', null);
```

### 3. `const` Constructor przy `FileOptions`

**Błąd:**

```
Error: Not a constant expression.
fileOptions: const FileOptions(upsert: true)
```

**Przyczyna:** Konstruktor `FileOptions` w nowszych wersjach SDK nie jest `const`.
**Rozwiązanie:** Usunięto słowo kluczowe `const`:

```dart
fileOptions: FileOptions(upsert: true)
```

### 4. Brakujący Import `FileOptions`

**Błąd:**

```
Error: The method 'FileOptions' isn't defined for the type 'ReportsRepository'.
```

**Przyczyna:** Klasa `FileOptions` znajduje się w pakiecie `supabase_flutter`, który nie był zaimportowany w pliku repozytorium (używano tylko `SupabaseService`).
**Rozwiązanie:** Dodano import:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

### 5. Brakujące Design Tokens

**Błąd:**

```
Error: Member not found: 'textSecondary'.
```

**Przyczyna:** Użyto kolorów `textSecondary` i `border`, które nie były zdefiniowane w `HaccpDesignTokens`.
**Rozwiązanie:** Dopisano brakujące stałe w `design_tokens.dart`.

---

## Archiwum Problemów (Wcześniejsze Sprinty)

### 6. `dart:io` na Web

**Błąd:** `Unsupported operation: Platform._operatingSystem`
**Przyczyna:** Używanie biblioteki `dart:io` (np. `File`, `Platform`) w kodzie kompilowanym na Web.
**Rozwiązanie:**

- Zamiana `File` na `XFile` (cross-platform).
- Użycie `kIsWeb` do warunkowego wykonywania kodu specyficznego dla platformy.
- Użycie `universal_html` lub warunkowych importów dla operacji na plikach (np. zapisywanie PDF).

### 7. Supabase `count` property

**Błąd:** `The getter 'count' isn't defined for the type 'int'.`
**Przyczyna:** W starszych wersjach `count` zwracał obiekt, teraz zwraca bezpośrednio `int`.
**Rozwiązanie:** Używanie wartości bezpośrednio (np. `if (count > 0)`).

### 8. Kolejność filtrów w Supabase

**Błąd:** Metody filtrujące nie działają po `order()` lub `limit()`.
**Przyczyna:** Chainowanie metod w Supabase wymaga zachowania kolejności: **Najpierw Filtry, potem Modyfikatory**.
**Rozwiązanie:**

- Źle: `.select().order(...).eq(...)`
- Dobrze: `.select().eq(...).order(...)`

### 9. Cache na Vercel (Stale Build)

**Objaw:** Wprowadzone poprawki nie są widoczne na produkcji mimo sukcesu "Deployment".
**Przyczyna:** Vercel/Flutter może cache'ować stare artefakty kompilacji.
**Rozwiązanie:**

- Wymuszenie czystego builda (Redeploy bez cache w Vercel dashboard).
- Zmiana `pubspec.yaml` (np. podbicie wersji), co wymusza pobranie zależności na nowo.

## Dobre Praktyki Deployu na Vercel

1. **Zawsze sprawdzaj logi builda:** Błędy Dart są wypisywane w sekcji "Build".
2. **Lokalny test builda:** `flutter build web --release` lokalnie wyłapie 99% błędów przed wysłaniem na serwer.
3. **Unikaj `dart:io`:** Jeśli importujesz `dart:io`, upewnij się, że jest to w pliku, który nie jest kompilowany na Web, lub użyj `if (kIsWeb)`.
