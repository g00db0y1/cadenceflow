import 'package:flutter/material.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Dedicated "How to Use CadenceFlow" guide sheet.
/// Keeps explanations out of the everyday workspace while giving users a
/// clear, friendly reference whenever they want to learn how features work.
class AppGuideSheet extends StatelessWidget {
  const AppGuideSheet({
    super.key,
    required this.controller,
  });

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Use CadenceFlow',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'A simple guide to organizing your day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _GuideSectionCard(
              icon: Icons.dashboard_customize_rounded,
              accentColor: CadenceFlowTheme.q1CoralRed,
              title: '1. Focus Tab — Sort by What Matters',
              description:
                  'Instead of one giant stressful to-do list, your tasks are grouped into four simple buckets:\n'
                  '• Do First: Urgent and important things to finish today.\n'
                  '• Plan Ahead: Important goals to set aside time for.\n'
                  '• Quick Tasks: Small errands that take just a few minutes.\n'
                  '• For Later: Low-priority ideas to keep out of your way.',
            ),
            const SizedBox(height: 12),
            const _GuideSectionCard(
              icon: Icons.calendar_month_rounded,
              accentColor: CadenceFlowTheme.q2DeepTeal,
              title: '2. Calendar Tab — Daily, Weekly & Monthly Views',
              description:
                  'Switch between Daily, Weekly, and Monthly views at the top of the Calendar tab:\n'
                  '• Monthly View: See colored dots for busy days across the whole month and tap any date to inspect it.\n'
                  '• Weekly View: Compare your workload across all 7 days of the week.\n'
                  '• Daily View: Follow your morning, afternoon, and evening schedule step by step.',
            ),
            const SizedBox(height: 12),
            const _GuideSectionCard(
              icon: Icons.repeat_rounded,
              accentColor: CadenceFlowTheme.q3WarmAmber,
              title: '3. Routines Tab — Habits That Never Pile Up',
              description:
                  'Create habits that repeat Daily, Every 2 Days, Weekly, Every 2 Weeks, or Monthly. '
                  'When you tap "Mark Done", your streak goes up and the app automatically sets your next due date—so even if you miss a day, overdue items never stack up.',
            ),
            const SizedBox(height: 12),
            const _GuideSectionCard(
              icon: Icons.notifications_active_rounded,
              accentColor: CadenceFlowTheme.primaryTealLight,
              title: '4. Reminders Tab — Insistent Alerts',
              description:
                  'Important meetings and priority tasks can use insistent reminders. '
                  'If you miss the first alert, the app keeps nudging you every few minutes until you tap "Got It", "Snooze 10m", or "Mark Done".',
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.reopenOnboardingWizard();
              },
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Run First-Time Setup Walkthrough Again'),
            ),
          ],
        );
      },
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: accentColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withValues(alpha: 0.16),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
