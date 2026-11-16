import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/clerk_auth_service.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/account_preferences_sheet.dart';
import '../widgets/app_guide_sheet.dart';
import '../widgets/brand_icon.dart';
import '../widgets/task_composer_sheet.dart';
import 'alerts_screen.dart';
import 'cadence_screen.dart';
import 'calendar_screen.dart';
import 'matrix_screen.dart';
import 'onboarding_setup_screen.dart';

/// Adaptive Material 3 Main Scaffold:
/// - Automatically launches the First-Startup Guided Setup Wizard when
///   `!controller.isOnboardingCompleted`.
/// - Provides 4 primary tabs: **Focus**, **Calendar**, **Routines**, and **Reminders**.
/// - Includes a dedicated **How to Use (?)** button in the top AppBar.
/// - Displays an insistent in-app reminder banner whenever an urgent alert is ringing.
class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.authService,
    required this.controller,
  });

  final ClerkAuthService authService;
  final ProductivityController controller;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (!widget.controller.isOnboardingCompleted) {
          return OnboardingSetupScreen(controller: widget.controller);
        }

        final scheme = Theme.of(context).colorScheme;
        final urgentCount = widget.controller.urgentAttentionCount;
        final activeFeed = widget.controller.activeAttentionFeed;
        final user = widget.authService.currentUser;

        final pages = <Widget>[
          MatrixScreen(
            controller: widget.controller,
            onNavigateToAlerts: () => setState(() => _selectedIndex = 3),
          ),
          CalendarScreen(controller: widget.controller),
          CadenceScreen(controller: widget.controller),
          AlertsScreen(controller: widget.controller),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final useRail = constraints.maxWidth >= 720;

            return Scaffold(
              appBar: AppBar(
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CadenceFlowBrandIcon(size: 34, borderRadius: 10),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'CadenceFlow',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Dedicated How to Use / App Guide Button
                  IconButton(
                    tooltip: 'How to Use CadenceFlow',
                    onPressed: () => _openGuideSheet(context),
                    icon: const Icon(Icons.help_outline_rounded),
                  ),

                  // Friendly Save/Sync Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppConfig.isCloudSyncEnabled
                          ? CadenceFlowTheme.q2DeepTeal.withValues(alpha: 0.14)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppConfig.isCloudSyncEnabled
                              ? Icons.cloud_done_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppConfig.isCloudSyncEnabled
                              ? 'Cloud Synced'
                              : 'Saved',
                          style: CadenceFlowTheme.monoStyle(
                            context,
                            fontSize: 11,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // User Avatar Button
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openAccountSheet(context),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: scheme.primary,
                        child: Text(
                          user?.initials ?? 'CF',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    // Live Insistent Reminder Banner when an alert is ringing
                    if (activeFeed.isNotEmpty && _selectedIndex != 3)
                      _buildInsistentAlertBanner(context, activeFeed.first),
                    Expanded(
                      child: Row(
                        children: [
                          if (useRail)
                            NavigationRail(
                              selectedIndex: _selectedIndex,
                              onDestinationSelected: (i) =>
                                  setState(() => _selectedIndex = i),
                              labelType: NavigationRailLabelType.all,
                              destinations: [
                                const NavigationRailDestination(
                                  icon: Icon(Icons.dashboard_outlined),
                                  selectedIcon: Icon(Icons.dashboard_rounded),
                                  label: Text('Focus'),
                                ),
                                const NavigationRailDestination(
                                  icon: Icon(Icons.calendar_month_outlined),
                                  selectedIcon:
                                      Icon(Icons.calendar_month_rounded),
                                  label: Text('Calendar'),
                                ),
                                const NavigationRailDestination(
                                  icon: Icon(Icons.repeat_outlined),
                                  selectedIcon: Icon(Icons.repeat_rounded),
                                  label: Text('Routines'),
                                ),
                                NavigationRailDestination(
                                  icon: _buildAlertBadgeIcon(
                                    urgentCount,
                                    selected: false,
                                  ),
                                  selectedIcon: _buildAlertBadgeIcon(
                                    urgentCount,
                                    selected: true,
                                  ),
                                  label: const Text('Reminders'),
                                ),
                              ],
                            ),
                          Expanded(child: pages[_selectedIndex]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: useRail
                  ? null
                  : NavigationBar(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (i) =>
                          setState(() => _selectedIndex = i),
                      destinations: [
                        const NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: 'Focus',
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.calendar_month_outlined),
                          selectedIcon: Icon(Icons.calendar_month_rounded),
                          label: 'Calendar',
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.repeat_outlined),
                          selectedIcon: Icon(Icons.repeat_rounded),
                          label: 'Routines',
                        ),
                        NavigationDestination(
                          icon: _buildAlertBadgeIcon(
                            urgentCount,
                            selected: false,
                          ),
                          selectedIcon: _buildAlertBadgeIcon(
                            urgentCount,
                            selected: true,
                          ),
                          label: 'Reminders',
                        ),
                      ],
                    ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openComposerSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _selectedIndex == 0
                      ? 'Add Task'
                      : _selectedIndex == 1
                          ? 'Add to Calendar'
                          : _selectedIndex == 2
                              ? 'Add Routine'
                              : 'Add Reminder',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInsistentAlertBanner(BuildContext context, dynamic appt) {
    final session = widget.controller.reminderScheduler
        .sessionFor('appointment', appt.id as String);
    final pingCount = session?.pingCount ?? 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CadenceFlowTheme.q1CoralRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CadenceFlowTheme.q1CoralRed.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder Ringing (Alert #$pingCount): ${appt.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Repeats every ${appt.repingIntervalMinutes}m until you respond',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => widget.controller.acknowledgeAppointment(appt),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadgeIcon(int urgentCount, {required bool selected}) {
    final icon = Icon(
      selected
          ? Icons.notifications_active_rounded
          : Icons.notifications_none_rounded,
    );
    if (urgentCount <= 0) return icon;
    return Badge(
      backgroundColor: CadenceFlowTheme.q1CoralRed,
      label: Text('$urgentCount'),
      child: icon,
    );
  }

  void _openComposerSheet(BuildContext context) {
    final initialType = _selectedIndex == 2
        ? ComposerItemType.cadenceGoal
        : _selectedIndex == 3
            ? ComposerItemType.appointment
            : ComposerItemType.task;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskComposerSheet(
        controller: widget.controller,
        initialType: initialType,
        initialDate: _selectedIndex == 1
            ? widget.controller.selectedCalendarDate
            : null,
      ),
    );
  }

  void _openGuideSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AppGuideSheet(controller: widget.controller),
    );
  }

  void _openAccountSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AccountPreferencesSheet(
        authService: widget.authService,
        controller: widget.controller,
      ),
    );
  }
}
