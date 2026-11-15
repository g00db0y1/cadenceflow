import 'package:cadenceflow/services/clerk_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ClerkAuthService — Google OAuth, Email OTP & Supabase JWT Handshake', () {
    test('sendEmailOtpCode and verifyEmailOtpCode mint Clerk session and JWT',
        () async {
      final auth = ClerkAuthService();
      await auth.initialize();
      expect(auth.isAuthenticated, isFalse);

      final sent = await auth.sendEmailOtpCode('developer@cadenceflow.app');
      expect(sent, isTrue);
      expect(auth.pendingEmailForOtp, 'developer@cadenceflow.app');

      final verified = await auth.verifyEmailOtpCode('482910');
      expect(verified, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.email, 'developer@cadenceflow.app');
      expect(auth.currentUser?.id, startsWith('user_clerk_'));

      final jwt = await auth.getSupabaseAccessToken();
      expect(jwt, isNotNull);
      expect(jwt!.split('.').length, 3);
    });

    test('signInWithGoogle and signOut manage persistent session cleanly',
        () async {
      final auth = ClerkAuthService();
      await auth.initialize();

      await auth.signInWithGoogle(
        email: 'alex@gmail.com',
        displayName: 'Alex Mercier',
      );
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.initials, 'AM');

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
    });
  });
}
