/// Centralized runtime configuration for Clerk Auth and Supabase.
///
/// Values can be supplied at build/run time via `--dart-define`:
/// ```bash
/// flutter run \
///   --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_... \
///   --dart-define=CLERK_FRONTEND_API=https://your-instance.clerk.accounts.dev \
///   --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
/// ```
/// When left at their default placeholder values, CadenceFlow runs in
/// **Offline-First Local Mirror Mode** with zero crashes and full local persistence.
class AppConfig {
  const AppConfig._();

  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_REPLACE_WITH_YOUR_CLERK_PUBLISHABLE_KEY',
  );

  static const String clerkFrontendApi = String.fromEnvironment(
    'CLERK_FRONTEND_API',
    defaultValue: 'https://your-clerk-instance.clerk.accounts.dev',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-id.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.REPLACE_WITH_YOUR_SUPABASE_ANON_KEY',
  );

  static bool get isClerkConfigured =>
      clerkPublishableKey.isNotEmpty &&
      !clerkPublishableKey.contains('REPLACE_WITH') &&
      !clerkFrontendApi.contains('your-clerk-instance');

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project-id') &&
      !supabaseUrl.contains('placeholder.supabase.co') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('REPLACE_WITH') &&
      supabaseAnonKey != 'placeholder_anon_key';

  static bool get isCloudSyncEnabled =>
      isClerkConfigured && isSupabaseConfigured;
}
