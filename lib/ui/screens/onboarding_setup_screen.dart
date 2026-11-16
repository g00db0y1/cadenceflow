import 'package:flutter/material.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/brand_icon.dart';

/// First-startup guided setup wizard that walks the user through permissions,
/// insistent notification settings, and daily preferences in friendly human steps.
class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.controller,
  });

  final ProductivityController controller;

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  int _currentStep = 0;
  late int _repingMinutes;
  late bool _aggressiveEnabled;
  late int _dailyStartHour;
  late ThemeMode _selectedTheme;
  bool _permissionsChecked = false;
  bool _testAlertSent = false;

  @override
  void initState() {
    super.initState();
    _repingMinutes = widget.controller.defaultRepingMinutes;
    _aggressiveEnabled = widget.controller.aggressiveModeEnabled;
    _dailyStartHour = widget.controller.dailyStartHour;
    _selectedTheme = widget.controller.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CadenceFlowBrandIcon(size: 30, borderRadius: 8),
            SizedBox(width: 10),
            Text('Quick Setup'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _finishSetup,
            child: const Text('Skip Setup'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Step Progress Header
                Row(
                  children: List.generate(3, (index) {
                    final active = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: CadenceFlowTheme.monoStyle(
                    context,
                    fontSize: 12,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                if (_currentStep == 0) _buildStep1Welcome(context, scheme),
                if (_currentStep == 1) _buildStep2Notifications(context, scheme),
                if (_currentStep == 2) _buildStep3Ready(context, scheme),

                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_currentStep > 0) ...[
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _currentStep -= 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          if (_currentStep < 2) {
                            setState(() => _currentStep += 1);
                          } else {
                            _finishSetup();
                          }
                        },
                        icon: Icon(
                          _currentStep < 2
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_rounded,
                        ),
                        label: Text(
                          _currentStep < 2
                              ? 'Continue'
                              : 'Finish Setup & Open App',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Welcome(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: scheme.primary,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome! Let\'s Tailor Your Day',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'CadenceFlow helps you focus on your most important tasks, view your schedule on a Daily, Weekly, or Monthly calendar, and build lasting routines.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'When do you like to start planning your morning?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [7, 8, 9, 10].map((hour) {
              return ChoiceChip(
                label: Text('$hour:00 AM'),
                selected: _dailyStartHour == hour,
                onSelected: (_) => setState(() => _dailyStartHour = hour),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose your preferred look',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
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
            selected: {_selectedTheme},
            onSelectionChanged: (s) {
              setState(() => _selectedTheme = s.first);
              widget.controller.setThemeMode(s.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Notifications(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: CadenceFlowTheme.q3WarmAmber,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Never Miss an Important Reminder',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Turn on notifications so CadenceFlow can alert you on time and keep nudging you when something urgent needs your attention.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () async {
              await widget.controller.reminderScheduler.requestPermissions();
              await widget.controller.reminderScheduler
                  .requestExactAlarmPermission();
              if (!mounted) return;
              setState(() => _permissionsChecked = true);
            },
            icon: Icon(
              _permissionsChecked
                  ? Icons.verified_rounded
                  : Icons.notifications_active_rounded,
            ),
            label: Text(
              _permissionsChecked
                  ? 'Notifications & Alarms Enabled'
                  : 'Allow Notifications & Reminders',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep Nudging Until Answered'),
            subtitle: const Text(
              'Repeats important reminders automatically until you tap Got It, Snooze, or Done.',
            ),
            value: _aggressiveEnabled,
            onChanged: (v) => setState(() => _aggressiveEnabled = v),
          ),
          const SizedBox(height: 10),
          Text(
            'How often should unread reminders repeat?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('Every 5m')),
              ButtonSegment(value: 10, label: Text('Every 10m')),
              ButtonSegment(value: 15, label: Text('Every 15m')),
            ],
            selected: {_repingMinutes},
            onSelectionChanged: (s) =>
                setState(() => _repingMinutes = s.first),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.controller.triggerTestAggressiveAlert();
              if (!mounted) return;
              setState(() => _testAlertSent = true);
            },
            icon: const Icon(Icons.campaign_rounded),
            label: Text(
              _testAlertSent
                  ? 'Test Reminder Triggered!'
                  : 'Send a Quick Test Reminder',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Ready(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: CadenceFlowTheme.q2DeepTeal,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withValues(alpha: 0.16),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'re Ready to Go!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Here is what we have set up for you:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            icon: Icons.wb_sunny_rounded,
            label: 'Morning planning starts at $_dailyStartHour:00 AM',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.notifications_active_rounded,
            label: _aggressiveEnabled
                ? 'Insistent reminders repeat every $_repingMinutes minutes'
                : 'Standard single reminders enabled',
          ),
          const SizedBox(height: 8),
          const _SummaryRow(
            icon: Icons.calendar_month_rounded,
            label: 'Daily, Weekly, and Monthly Calendar views ready',
          ),
          const SizedBox(height: 8),
          const _SummaryRow(
            icon: Icons.help_outline_rounded,
            label:
                'Tap the Help (?) icon anytime for a simple guide to every feature',
          ),
        ],
      ),
    );
  }

  Future<void> _finishSetup() async {
    await widget.controller.completeOnboarding(
      repingMinutes: _repingMinutes,
      aggressiveEnabled: _aggressiveEnabled,
      dailyStartHour: _dailyStartHour,
      selectedThemeMode: _selectedTheme,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
