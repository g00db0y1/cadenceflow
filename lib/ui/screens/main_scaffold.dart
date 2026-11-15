import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/clerk_auth_service.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/account_preferences_sheet.dart';
import '../widgets/task_composer_sheet.dart';
import 'alerts_screen.dart';
import 'cadence_screen.dart';
import 'matrix_screen.dart';

/// Adaptive Material 3 Main Scaffold:
/// - Uses bottom `NavigationBar` on compact Android phones like the **itel Power 70**
/// - Switches to `NavigationRail` on tablet/foldable/wide viewports
/// - Displays live social-style unread badge counts on the **Alerts** tab
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
        final scheme = Theme.of(context).colorScheme;
        final urgentCount = widget.controller.urgentAttentionCount;
        final user = widget.authService.currentUser;

        final pages = <Widget>[
          MatrixScreen(
            controller: widget.controller,
            onNavigateToAlerts: () => setState(() => _selectedIndex = 2),
          ),
          CadenceScreen(controller: widget.controller),
          AlertsScreen(controller: widget.controller),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final useRail = constraints.maxWidth >= 720;

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        color: scheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('CadenceFlow'),
                  ],
                ),
                actions: [
                  // Sync Status Badge
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
                              : Icons.offline_pin_rounded,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppConfig.isCloudSyncEnabled
                              ? 'Supabase Sync'
                              : 'Offline Mirror',
                          style: CadenceFlowTheme.monoStyle(
                            context,
                            fontSize: 11,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Clerk User Avatar Button
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
                            icon: Icon(Icons.grid_view_outlined),
                            selectedIcon: Icon(Icons.grid_view_rounded),
                            label: Text('Today'),
                          ),
                          const NavigationRailDestination(
                            icon: Icon(Icons.repeat_outlined),
                            selectedIcon: Icon(Icons.repeat_rounded),
                            label: Text('Cadences'),
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
                            label: const Text('Alerts'),
                          ),
                        ],
                      ),
                    Expanded(child: pages[_selectedIndex]),
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
                          icon: Icon(Icons.grid_view_outlined),
                          selectedIcon: Icon(Icons.grid_view_rounded),
                          label: 'Today & Matrix',
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.repeat_outlined),
                          selectedIcon: Icon(Icons.repeat_rounded),
                          label: 'Cadences',
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
                          label: 'Alerts',
                        ),
                      ],
                    ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openComposerSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _selectedIndex == 0
                      ? 'New Task'
                      : _selectedIndex == 1
                          ? 'New Cadence'
                          : 'New Alert',
                ),
              ),
            );
          },
        );
      },
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
    final initialType = _selectedIndex == 1
        ? ComposerItemType.cadenceGoal
        : _selectedIndex == 2
            ? ComposerItemType.appointment
            : ComposerItemType.task;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskComposerSheet(
        controller: widget.controller,
        initialType: initialType,
      ),
    );
  }

  void _openAccountSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => AccountPreferencesSheet(
        authService: widget.authService,
        controller: widget.controller,
      ),
    );
  }
}
