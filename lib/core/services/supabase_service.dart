import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class SupabaseService {
  static Future<void> ensureAuthenticatedSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return;

    final response = await auth.signInAnonymously();
    if (response.session == null) {
      throw StateError(
        'Brak sesji Supabase Auth po signInAnonymously(). '
        'Sprawdz czy Anonymous Sign-Ins sa wlaczone w Supabase Auth settings.',
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
