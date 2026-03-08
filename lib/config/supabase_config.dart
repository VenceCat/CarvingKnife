abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fujllbtshauouzcyoifc.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_La-duqhIVkU_7rOegZi12Q_YYnf9957',
  );

  static const String emailConfirmRedirectTo = String.fromEnvironment(
    'SUPABASE_EMAIL_CONFIRM_REDIRECT',
    defaultValue: 'carvingknife://login-callback',
  );

  static const String passwordResetRedirectTo = String.fromEnvironment(
    'SUPABASE_RESET_PASSWORD_REDIRECT',
    defaultValue: 'carvingknife://reset-password',
  );

  static bool get isConfigured =>
      url.startsWith('http') &&
      !url.contains('YOUR_SUPABASE_URL') &&
      anonKey.isNotEmpty &&
      !anonKey.contains('YOUR_SUPABASE_ANON_KEY');
}
