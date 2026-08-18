import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project credentials (SRS §7.2). The anon key is safe to ship in
/// client builds — every table is RLS-locked to auth.uid() = user_id
/// (docs/SRS.md §NFR-3.5, supabase/migrations/0010_rls_policies.sql), so the
/// anon key alone grants no access to anything until the holder signs in.
///
/// Fill these in from your Supabase project's Settings > API page after
/// running `supabase link` / applying supabase/migrations. Left blank here
/// on purpose — this repo has no project provisioned yet.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> initialize() async {
    // supabase_flutter renamed anonKey -> publishableKey; SUPABASE_ANON_KEY
    // is still what the Supabase dashboard's API settings page calls it.
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
