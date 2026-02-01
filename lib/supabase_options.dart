// Supabase Configuration for Vet2U Clinic App
// Copy this file to supabase_options.dart and fill in your credentials
// Get these from Supabase Dashboard → Settings → API

class SupabaseOptions {
  /// Supabase Project URL
  /// Format: https://[your-project-ref].supabase.co
  /// Get this from: Supabase Dashboard → Settings → API → Project URL
  static const String projectUrl = 'https://rxtksgamvkqpepitpool.supabase.co';

  /// Supabase Anon Public Key
  /// Format: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  /// Get this from: Supabase Dashboard → Settings → API → anon public
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4dGtzZ2FtdmtxcGVwaXRwb29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4NjkzMzAsImV4cCI6MjA4NTQ0NTMzMH0.5wXEI7El6sK9hMbG_o00MbjHcf41wFBpbLHzh1bTpkk';

  /// Database Connection Info (for direct connections if needed)
  /// These are for reference - Flutter app uses the URL and anonKey above
  static const String dbHost = 'db.rxtksgamvkqpepitpool.supabase.co';
  static const int dbPort = 5432;
  static const String dbName = 'postgres';
  static const String dbUser = 'postgres';
}

// Note about "postgres" user:
// - "postgres" is the default superuser in PostgreSQL/Supabase
// - The Flutter app uses the "anon" key with Row Level Security (RLS)
// - RLS policies control what data users can access
// - The "postgres" user is mainly for database administration
