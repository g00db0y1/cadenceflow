import 'dart:convert';

import 'package:cadenceflow/config/app_config.dart';
import 'package:cadenceflow/services/clerk_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ClerkAuthService — Google OAuth, Email OTP & Supabase JWT Handshake', () {
    test('binds Clerk application app_3MCWyxqnF0GnpRlYDILJgqs2pZ4 and decodes publishable keys',
        () async {
      expect(
        AppConfig.clerkApplicationId,
        'app_3MCWyxqnF0GnpRlYDILJgqs2pZ4',
      );
      final encodedDomain =
          base64.encode(utf8.encode(r'cadenceflow-dev.clerk.accounts.dev$'));
      final samplePk = 'pk_test_$encodedDomain';
      expect(
        AppConfig.decodeFrontendApiFromPublishableKey(samplePk),
        'https://cadenceflow-dev.clerk.accounts.dev',
      );

      final auth = ClerkAuthService();
      await auth.initialize();
      expect(auth.applicationId, 'app_3MCWyxqnF0GnpRlYDILJgqs2pZ4');
      await auth.configurePublishableKey(samplePk);
      expect(auth.activePublishableKey, samplePk);
      expect(
        auth.activeFrontendApi,
        'https://cadenceflow-dev.clerk.accounts.dev',
      );
      expect(auth.isLiveClerkConfigured, isTrue);
    });

    test('sendEmailOtpCode and verifyEmailOtpCode mint Clerk session and JWT for Sign-In and Sign-Up',
        () async {
      final auth = ClerkAuthService();
      await auth.initialize();
      expect(auth.isAuthenticated, isFalse);

      final sent = await auth.sendEmailOtpCode(
        'developer@cadenceflow.app',
        isSignUp: true,
      );
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

