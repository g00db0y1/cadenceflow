import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/clerk_auth_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/brand_icon.dart';

/// Welcome, Sign-In, and Sign-Up screen powered by Clerk Auth
/// (`app_3MCWyxqnF0GnpRlYDILJgqs2pZ4`) with warm, human-friendly wording
/// and solid card styling.
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
  bool _isSignUpMode = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController =
      TextEditingController(text: '482910');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pendingEmail = widget.authService.pendingEmailForOtp;
    final isClerkReady = widget.authService.isLiveClerkConfigured;

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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CadenceFlowBrandIcon(
                        size: 72,
                        borderRadius: 20,
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
                    'Focus on what matters today, plan your calendar, and never miss an important reminder.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Friendly Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: CadenceFlowTheme.solidCardDecoration(
                      context,
                      accentColor: AppConfig.isCloudSyncEnabled || isClerkReady
                          ? CadenceFlowTheme.q2DeepTeal
                          : CadenceFlowTheme.q3WarmAmber,
                      borderRadius: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppConfig.isCloudSyncEnabled || isClerkReady
                              ? Icons.cloud_done_rounded
                              : Icons.phone_android_rounded,
                          size: 20,
                          color: AppConfig.isCloudSyncEnabled || isClerkReady
                              ? CadenceFlowTheme.q2DeepTeal
                              : CadenceFlowTheme.q3WarmAmber,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppConfig.isCloudSyncEnabled || isClerkReady
                                ? 'Cloud Account Ready (${widget.authService.applicationId})'
                                : 'Works Offline — Saved Directly on Your Phone',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Solid Sign-In / Sign-Up Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: CadenceFlowTheme.solidCardDecoration(
                      context,
                      accentColor: scheme.primary,
                      highlighted: true,
                    ),
                    child: pendingEmail == null
                        ? _buildSignInOrSignUpOptions(context, scheme)
                        : _buildOtpVerification(context, scheme, pendingEmail),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInOrSignUpOptions(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome to CadenceFlow',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in or create an account to back up your tasks, calendar, and routines across devices.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),

        // Sign In / Sign Up Mode Toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.login_rounded, size: 16),
              label: Text('Sign In'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: Text('Sign Up'),
            ),
          ],
          selected: {_isSignUpMode},
          onSelectionChanged: (s) {
            setState(() => _isSignUpMode = s.first);
          },
        ),
        const SizedBox(height: 18),

        FilledButton.icon(
          onPressed: widget.authService.isLoading
              ? null
              : () => widget.authService.signInWithGoogle(),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
          label: const Text('Continue with Google'),
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
                'OR SIGN IN WITH EMAIL',
                style: CadenceFlowTheme.monoStyle(context, fontSize: 10),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        if (_isSignUpMode) ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'Alex Mercier',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

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
                    displayName: _nameController.text,
                    isSignUp: _isSignUpMode,
                  ),
          icon: const Icon(Icons.mark_email_read_outlined),
          label: Text(_isSignUpMode ? 'Create Account' : 'Send Login Code'),
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
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Continue on This Phone'),
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
          'Check Your Email',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a 6-digit login code to $email',
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
            labelText: '6-Digit Code',
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
          label: const Text('Verify & Continue'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.authService.cancelPendingOtp,
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
