import 'dart:convert';

/// Centralized runtime configuration for Clerk Auth (`app_3MCWyxqnF0GnpRlYDILJgqs2pZ4`)
/// and Supabase.
///
/// Values can be supplied at build/run time via `--dart-define`:
/// ```bash
/// flutter run \
///   --dart-define=CLERK_APPLICATION_ID=app_3MCWyxqnF0GnpRlYDILJgqs2pZ4 \
///   --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_... \
///   --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
/// ```
/// Notice that `CLERK_FRONTEND_API` is automatically decoded from
/// `CLERK_PUBLISHABLE_KEY` (`pk_test_...` or `pk_live_...`) when not explicitly
/// passed. When left at default placeholder values, CadenceFlow runs in
/// **Offline-First Local Mirror Mode** with full local persistence.
class AppConfig {
  const AppConfig._();

  /// Dashboard-selected Clerk Application ID.
  static const String clerkApplicationId = String.fromEnvironment(
    'CLERK_APPLICATION_ID',
    defaultValue: 'app_3MCWyxqnF0GnpRlYDILJgqs2pZ4',
  );

  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment(
        'EXPO_PUBLIC_CLERK_PUBLISHABLE_KEY',
        defaultValue: 'pk_test_REPLACE_WITH_YOUR_CLERK_PUBLISHABLE_KEY',
      ),
    ),
  );

  static const String _rawClerkFrontendApi = String.fromEnvironment(
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

  /// Resolves the Clerk Frontend API URL either from `--dart-define=CLERK_FRONTEND_API`
  /// or by decoding the Base64 domain embedded inside `CLERK_PUBLISHABLE_KEY`.
  static String get clerkFrontendApi {
    if (!_rawClerkFrontendApi.contains('your-clerk-instance')) {
      return _rawClerkFrontendApi;
    }
    return decodeFrontendApiFromPublishableKey(clerkPublishableKey) ??
        _rawClerkFrontendApi;
  }

  /// Decodes the Clerk Frontend API origin (`https://<domain>`) embedded inside
  /// a standard Clerk `pk_test_...` or `pk_live_...` publishable key.
  static String? decodeFrontendApiFromPublishableKey(String publishableKey) {
    final trimmed = publishableKey.trim();
    String? encodedPart;
    if (trimmed.startsWith('pk_test_')) {
      encodedPart = trimmed.substring('pk_test_'.length);
    } else if (trimmed.startsWith('pk_live_')) {
      encodedPart = trimmed.substring('pk_live_'.length);
    }
    if (encodedPart == null ||
        encodedPart.isEmpty ||
        encodedPart.contains('REPLACE_WITH') ||
        encodedPart == 'PLACEHOLDER') {
      return null;
    }
    try {
      final normalized = base64.normalize(encodedPart);
      final decoded = utf8.decode(base64.decode(normalized));
      final host = decoded.endsWith(r'$')
          ? decoded.substring(0, decoded.length - 1)
          : decoded;
      if (host.isEmpty || !host.contains('.')) return null;
      return host.startsWith('http') ? host : 'https://$host';
    } catch (_) {
      return null;
    }
  }

  static bool get isClerkConfigured =>
      clerkPublishableKey.isNotEmpty &&
      !clerkPublishableKey.contains('REPLACE_WITH') &&
      clerkPublishableKey != 'pk_test_PLACEHOLDER' &&
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
