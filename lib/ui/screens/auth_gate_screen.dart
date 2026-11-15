import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/clerk_auth_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/brand_icon.dart';

/// Branded Clerk Authentication Gate offering:
/// 1. 1-Tap Google Sign-In (Clerk OAuth)
/// 2. Passwordless Email OTP verification (Clerk Frontend API)
/// 3. Instant Offline-First Workspace Mode (works out of the box with placeholders)
class ClerkAuthGateScreen extends StatefulWidget {
  const ClerkAuthGateScreen({
    super.key,
    required this.authService,
  });

  final ClerkAuthService authService;

  @override
  State<ClerkAuthGateScreen> createState() => _ClerkAuthGateScreenState();
}

class _ClerkAuthGateScreenState extends State<ClerkAuthGateScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController =
      TextEditingController(text: '482910');

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pendingEmail = widget.authService.pendingEmailForOtp;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Logo & Tagline
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CadenceFlowBrandIcon(
                        size: 68,
                        borderRadius: 18,
                        showGlow: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CadenceFlow',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Eisenhower Priority • 5-Tier Cadence Goals • Persistent Social-Style Reminders',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Clerk + Supabase Connection Readiness Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppConfig.isCloudSyncEnabled
                          ? CadenceFlowTheme.q2DeepTeal.withValues(alpha: 0.12)
                          : CadenceFlowTheme.q3WarmAmber
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConfig.isCloudSyncEnabled
                            ? CadenceFlowTheme.q2DeepTeal.withValues(alpha: 0.4)
                            : CadenceFlowTheme.q3WarmAmber
                                .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppConfig.isCloudSyncEnabled
                              ? Icons.cloud_done_rounded
                              : Icons.offline_bolt_rounded,
                          size: 20,
                          color: AppConfig.isCloudSyncEnabled
                              ? CadenceFlowTheme.q2DeepTeal
                              : CadenceFlowTheme.q3WarmAmber,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppConfig.isCloudSyncEnabled
                                ? 'Clerk Auth + Supabase RLS Active'
                                : 'Placeholders Active • Offline-First Local Mirror Ready (itel Power 70 Optimized)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card Container
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: pendingEmail == null
                          ? _buildSignInOptions(context, scheme)
                          : _buildOtpVerification(context, scheme, pendingEmail),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInOptions(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in with Clerk',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Syncs your tasks, cadence streaks, and appointment alarms to Supabase PostgreSQL.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),

        // 1-Tap Google Sign-In via Clerk
        FilledButton.icon(
          onPressed: widget.authService.isLoading
              ? null
              : () => widget.authService.signInWithGoogle(),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
          label: const Text('Continue with Google (Clerk OAuth)'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR PASSWORDLESS EMAIL OTP',
                style: CadenceFlowTheme.monoStyle(context, fontSize: 10),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email address',
            hintText: 'you@example.com',
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.authService.isLoading
              ? null
              : () => widget.authService.sendEmailOtpCode(
                    _emailController.text,
                  ),
          icon: const Icon(Icons.mark_email_read_outlined),
          label: const Text('Send Clerk Verification Code'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),

        if (widget.authService.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.authService.errorMessage!,
            style: TextStyle(color: scheme.error, fontSize: 13),
          ),
        ],

        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: widget.authService.isLoading
              ? null
              : () => widget.authService.continueInOfflineWorkspace(),
          icon: const Icon(Icons.phone_android_rounded, size: 18),
          label: const Text('Start Immediately in Local Offline Workspace'),
        ),
      ],
    );
  }

  Widget _buildOtpVerification(
    BuildContext context,
    ColorScheme scheme,
    String email,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Verification Code',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Clerk sent a 6-digit one-time code to $email',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          style: CadenceFlowTheme.monoStyle(context, fontSize: 18),
          decoration: InputDecoration(
            labelText: '6-Digit Clerk OTP Code',
            prefixIcon: const Icon(Icons.lock_clock_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.authService.isLoading
              ? null
              : () => widget.authService.verifyEmailOtpCode(
                    _otpController.text,
                  ),
          icon: const Icon(Icons.verified_user_rounded),
          label: const Text('Verify & Hydrate Workspace'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.authService.cancelPendingOtp,
          child: const Text('Use a different email or method'),
        ),
      ],
    );
  }
}
