import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/enums.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Reminders Tab: Active Insistent Reminders & Upcoming Appointments
/// with solid, tactile cards and human-friendly wording.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.controller,
  });

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attentionFeed = controller.activeAttentionFeed;
    final allAppointments = controller.appointments;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // 1. Solid Insistent Reminder Status & Test Card
        _buildReadinessBanner(context, scheme),
        const SizedBox(height: 18),

        // 2. Active Reminders (Ringing / Unanswered Alerts)
        Row(
          children: [
            const Icon(
              Icons.campaign_rounded,
              color: CadenceFlowTheme.q1CoralRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Active Reminders (${attentionFeed.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (attentionFeed.isNotEmpty)
              TextButton.icon(
                onPressed: () =>
                    controller.reminderScheduler.simulateEscalationTick(),
                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                label: const Text('Nudge Again'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Important alerts repeat every ${controller.defaultRepingMinutes} minutes until you tap Got It, Snooze, or Mark Done.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),

        if (attentionFeed.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: CadenceFlowTheme.solidCardDecoration(context),
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: scheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'All caught up! No unanswered reminders are ringing right now.',
                  ),
                ),
              ],
            ),
          )
        else
          ...attentionFeed.map(
            (appt) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SocialAttentionCard(
                appointment: appt,
                controller: controller,
              ),
            ),
          ),

        const SizedBox(height: 22),

        // 3. Upcoming Appointments Timeline
        Text(
          'Upcoming Appointments (${allAppointments.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),

        if (allAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: CadenceFlowTheme.solidCardDecoration(context),
            child: const Text(
              'No appointments scheduled yet. Tap "Add Reminder" below to add one.',
            ),
          )
        else
          ...allAppointments.map(
            (appt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AppointmentTimelineTile(
                appointment: appt,
                controller: controller,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReadinessBanner(BuildContext context, ColorScheme scheme) {
    final activeSessions = controller.reminderScheduler.activeEscalationCount;
    final totalPings = controller.reminderScheduler.totalPingsDispatched;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CadenceFlowTheme.heroBannerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.alarm_on_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.aggressiveModeEnabled
                          ? 'Insistent Reminders Are On'
                          : 'Standard Reminders Are On',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeSessions ringing now • $totalPings alert${totalPings == 1 ? '' : 's'} sent this session',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await controller.triggerTestAggressiveAlert();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Insistent reminder triggered! Check your active alerts below.',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: CadenceFlowTheme.accentAmberDark,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.notifications_active_rounded, size: 17),
                label: const Text('Test Reminder Now'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await controller.reminderScheduler.requestPermissions();
                  await controller.reminderScheduler
                      .requestExactAlarmPermission();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification and alarm permissions are ready.',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                icon: const Icon(Icons.verified_outlined, size: 17),
                label: const Text('Check Permissions'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialAttentionCard extends StatelessWidget {
  const _SocialAttentionCard({
    required this.appointment,
    required this.controller,
  });

  final Appointment appointment;
  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final startsFormatted =
        DateFormat('EEE, MMM d • h:mm a').format(appointment.startsAtDateTime);
    final session = controller.reminderScheduler
        .sessionFor('appointment', appointment.id);
    final pingCount = session?.pingCount ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: CadenceFlowTheme.q1CoralRed,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: CadenceFlowTheme.q1CoralRed,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment.alertStatus.label.toUpperCase()} • ALERT #$pingCount • EVERY ${appointment.repingIntervalMinutes}M',
                      style: CadenceFlowTheme.monoStyle(
                        context,
                        fontSize: 11,
                        color: CadenceFlowTheme.q1CoralRed,
                      ),
                    ),
                    Text(
                      startsFormatted,
                      style: CadenceFlowTheme.monoStyle(
                        context,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            appointment.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (appointment.locationOrLink.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 15),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appointment.locationOrLink,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    controller.acknowledgeAppointment(appointment),
                icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                label: const Text('Got It'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    controller.snoozeAppointment(appointment, minutes: 10),
                icon: const Icon(Icons.snooze_rounded, size: 16),
                label: const Text('Snooze 10m'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => controller.completeAppointment(appointment),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Mark Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentTimelineTile extends StatelessWidget {
  const _AppointmentTimelineTile({
    required this.appointment,
    required this.controller,
  });

  final Appointment appointment;
  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final startsFormatted =
        DateFormat('MMM d, h:mm a').format(appointment.startsAtDateTime);

    return Container(
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: scheme.primary,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.14),
          child: Icon(Icons.event_available_rounded, color: scheme.primary),
        ),
        title: Text(
          appointment.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: appointment.alertStatus == AlertStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '$startsFormatted • ${appointment.leadMinutes}m early notice • ${appointment.alertStatus.label}',
              style: CadenceFlowTheme.monoStyle(context, fontSize: 11),
            ),
            if (appointment.locationOrLink.isNotEmpty)
              Text(
                appointment.locationOrLink,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'PING') {
              controller.triggerNowPing(appointment);
            } else if (action == 'DONE') {
              controller.completeAppointment(appointment);
            } else if (action == 'DELETE') {
              controller.deleteAppointment(appointment.id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'PING',
              child: Text('Ring Reminder Now'),
            ),
            PopupMenuItem(
              value: 'DONE',
              child: Text('Mark Done'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'DELETE',
              child: Text(
                'Delete Appointment',
                style: TextStyle(color: CadenceFlowTheme.q1CoralRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
