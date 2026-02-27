import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class AppInitializationException implements Exception {
  final String title;
  final String message;
  final List<String> remediationSteps;
  final Object? cause;

  const AppInitializationException({
    required this.title,
    required this.message,
    this.remediationSteps = const <String>[],
    this.cause,
  });

  @override
  String toString() {
    return '$title: $message';
  }
}

class SupabaseService {
  static Future<void> ensureAuthenticatedSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return;

    try {
      final response = await auth.signInAnonymously();
      if (response.session == null) {
        throw const AppInitializationException(
          title: 'Brak sesji Supabase Auth',
          message:
              'Nie udalo sie utworzyc sesji po signInAnonymously().',
          remediationSteps: <String>[
            'W Supabase otworz Authentication -> Providers.',
            'Wlacz Anonymous Sign-Ins i zapisz ustawienia.',
            'Odswiez aplikacje na Vercel.',
          ],
        );
      }
    } on AuthException catch (e) {
      if (e.code == 'anonymous_provider_disabled') {
        throw AppInitializationException(
          title: 'Anonymous Sign-Ins wylaczone',
          message:
              'Aplikacja wymaga anonimowej sesji Supabase do RLS i kontekstu kiosku.',
          remediationSteps: const <String>[
            'W Supabase otworz Authentication -> Providers.',
            'Wlacz Anonymous Sign-Ins i zapisz ustawienia.',
            'Odswiez aplikacje na Vercel.',
          ],
          cause: e,
        );
      }
      throw AppInitializationException(
        title: 'Blad logowania anonimowego',
        message: e.message,
        remediationSteps: const <String>[
          'Sprawdz ustawienia Supabase Auth.',
          'Sprawdz klucze SUPABASE_URL i SUPABASE_ANON_KEY w Vercel.',
          'Odswiez aplikacje po poprawkach.',
        ],
        cause: e,
      );
    } catch (e) {
      throw AppInitializationException(
        title: 'Blad inicjalizacji Supabase',
        message: e.toString(),
        remediationSteps: const <String>[
          'Sprawdz konfiguracje Supabase i siec.',
          'Odswiez aplikacje po poprawkach.',
        ],
        cause: e,
      );
    }
  }

  static Future<void> initialize() async {
    // Ensuring variables are present is handled by main or config check
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
    await ensureAuthenticatedSession();
  }

  static SupabaseClient get client => Supabase.instance.client;
  static SupabaseStorageClient get storage => client.storage;
  static GoTrueClient get auth => client.auth;
  static RealtimeClient get realtime => client.realtime;
}
