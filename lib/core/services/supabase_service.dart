import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class SupabaseService {
  static Future<void> initialize() async {
    // Ensuring variables are present is handled by main or config check
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static SupabaseStorageClient get storage => client.storage;
  static GoTrueClient get auth => client.auth;
  static RealtimeClient get realtime => client.realtime;
}
