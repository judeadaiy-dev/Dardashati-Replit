import 'package:supabase_flutter/supabase_flutter.dart';
import '../env.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentAuthUser => client.auth.currentUser;
  static String? get currentUserId => currentAuthUser?.id;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }
}
