import 'package:supabase_flutter/supabase_flutter.dart';

/// Remplis ces deux valeurs avec celles de ton projet Supabase
/// (Project Settings > API dans le dashboard supabase.com).
/// La clé "anon" est faite pour être embarquée côté client : la sécurité
/// est assurée par les policies RLS définies dans supabase/schema.sql.
class SupabaseConfig {
  static const url = 'https://nfshbiamzszeenmasxop.supabase.co';
  static const anonKey = 'sb_publishable_is5fB-8JZ50DAXt6TVw_2w_7rEazqCj';

  static Future<void> init() {
    return Supabase.initialize(url: url, publishableKey: anonKey);
  }
}

SupabaseClient get supabase => Supabase.instance.client;
