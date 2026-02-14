import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class SupabaseService {
  static Future<void> initialize() async {
    // Ensuring variables are present is handled by main or config check
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );

    // Directive 13: Ensure authenticated session (Anonymous) for RLS policies
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      try {
        await Supabase.instance.client.auth.signInAnonymously();
      } catch (e) {
        print('Anonymous Auth Error: $e'); // Fail gracefully, might work if public
      }
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static SupabaseStorageClient get storage => client.storage;
  static GoTrueClient get auth => client.auth;
  static RealtimeClient get realtime => client.realtime;
}
