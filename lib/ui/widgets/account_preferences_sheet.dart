import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/clerk_auth_service.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Account & Preferences Sheet accessible from the top-bar Clerk avatar:
/// - Displays Clerk User ID (`sub` claim mapped to Supabase RLS) & auth method
/// - Shows Cloud Sync vs. Offline Local Mirror status
/// - Configures persistent escalation re-ping interval (5m / 10m / 15m)
/// - Switches Light / Dark / System theme mode
/// - Signs out cleanly
class AccountPreferencesSheet extends StatelessWidget {
  const AccountPreferencesSheet({
    super.key,
    required this.authService,
    required this.controller,
  });

  final ClerkAuthService authService;
  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primary,
                child: Text(
                  user?.initials ?? 'CF',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'CadenceFlow User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Clerk sub: ${user?.id ?? 'local'}',
                      style: CadenceFlowTheme.monoStyle(context, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          // Sync Status Row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              AppConfig.isCloudSyncEnabled
                  ? Icons.cloud_done_rounded
                  : Icons.storage_rounded,
              color: scheme.primary,
            ),
            title: Text(
              AppConfig.isCloudSyncEnabled
                  ? 'Supabase PostgreSQL + Clerk RLS Active'
                  : 'Offline-First Local Mirror Active (Placeholders Set)',
            ),
            subtitle: const Text(
              'All tasks, cadences, and alarm triggers are mirrored locally for 100% offline reliability on reboot.',
            ),
          ),
          const SizedBox(height: 10),

          // Persistent Re-Ping Interval Selector
          Text(
            'Persistent Notification Escalation Re-Ping Interval',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('Every 5m')),
              ButtonSegment(value: 10, label: Text('Every 10m')),
              ButtonSegment(value: 15, label: Text('Every 15m')),
            ],
            selected: {controller.defaultRepingMinutes},
            onSelectionChanged: (s) {
              controller.setDefaultRepingMinutes(s.first);
            },
          ),
          const SizedBox(height: 16),

          // Theme Mode Selector
          Text(
            'Appearance & Theme (Teal & Amber Material 3)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded, size: 16),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded, size: 16),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded, size: 16),
                label: Text('Dark'),
              ),
            ],
            selected: {controller.themeMode},
            onSelectionChanged: (s) {
              controller.setThemeMode(s.first);
            },
          ),
          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await authService.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out of Clerk Session'),
          ),
        ],
      ),
    );
  }
}
