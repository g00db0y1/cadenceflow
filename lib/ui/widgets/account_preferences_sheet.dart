import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/clerk_auth_service.dart';
import '../../state/productivity_controller.dart';
import 'app_guide_sheet.dart';

/// Account, Preferences & Help Sheet accessible from the top-bar avatar:
/// - Displays signed-in account details & backup status in plain human language
/// - Opens the "How to Use CadenceFlow" guide or re-runs First-Time Setup
/// - Configures insistent reminder repeat interval (Every 5m / 10m / 15m)
/// - Switches Light / Dark / Auto theme mode
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

    return SingleChildScrollView(
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Backup Status Row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              AppConfig.isCloudSyncEnabled
                  ? Icons.cloud_done_rounded
                  : Icons.phone_android_rounded,
              color: scheme.primary,
            ),
            title: Text(
              AppConfig.isCloudSyncEnabled
                  ? 'Cloud Backup Connected'
                  : 'Saved on This Phone (Works Offline)',
            ),
            subtitle: const Text(
              'Your tasks, calendar, routines, and reminders are safely stored on your device.',
            ),
          ),

          // Dedicated App Guide & Setup Walkthrough
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.menu_book_rounded, color: scheme.primary),
            title: const Text('How to Use CadenceFlow'),
            subtitle: const Text(
              'Learn how Priority Groups, Calendar Views, Routines, and Reminders work.',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => AppGuideSheet(controller: controller),
              );
            },
          ),
          const SizedBox(height: 10),

          // Insistent Reminder Toggle & Interval Selector
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Insistent Reminders'),
            subtitle: const Text(
              'Keep nudging you automatically until you answer important alerts',
            ),
            value: controller.aggressiveModeEnabled,
            onChanged: (v) => controller.setAggressiveModeEnabled(v),
          ),
          const SizedBox(height: 6),
          Text(
            'Repeat Unanswered Reminders',
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
            'App Appearance',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded, size: 16),
                label: Text('Auto'),
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
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
