import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/enums.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Alerts Tab: Appointments Timeline & Social-Media-Style Persistent Attention Feed.
/// - Includes a non-blocking **Notification & Exact Alarm Readiness Banner**
///   for Android 13+ (`POST_NOTIFICATIONS` & `SCHEDULE_EXACT_ALARM`).
/// - Displays an urgent **Social-Style Attention Feed** with inline
///   **Acknowledge (`Got It`)**, **Snooze 10m**, and **Complete** buttons.
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
        // 1. Android 13+ Notification & Exact Alarm Readiness Banner
        _buildReadinessBanner(context, scheme),
        const SizedBox(height: 16),

        // 2. Social-Media-Style Attention Feed (Unacknowledged / Pinging Alerts)
        Row(
          children: [
            const Icon(
              Icons.campaign_rounded,
              color: CadenceFlowTheme.q1CoralRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Attention Feed (${attentionFeed.length} Active)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Social-style persistent reminders that re-ping every ${controller.defaultRepingMinutes}m until you tap Got It, Snooze, or Done.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),

        if (attentionFeed.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                      'All caught up! No unacknowledged persistent pings right now.',
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...attentionFeed.map(
            (appt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SocialAttentionCard(
                appointment: appt,
                controller: controller,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // 3. Chronological Appointments Timeline
        Text(
          'Upcoming & Scheduled Appointments (${allAppointments.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),

        if (allAppointments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No appointments scheduled yet. Tap + to add one.'),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.alarm_on_rounded,
            color: scheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persistent Alarm Readiness (itel Power 70 & Android 13+)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Offline alarm mirror active. Grant notification & exact alarm permissions so heads-up escalation banners never get silenced.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await controller.reminderScheduler.requestPermissions();
              await controller.reminderScheduler.requestExactAlarmPermission();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Verified POST_NOTIFICATIONS & SCHEDULE_EXACT_ALARM readiness.',
                  ),
                ),
              );
            },
            child: const Text('Verify'),
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

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: CadenceFlowTheme.q1CoralRed,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: CadenceFlowTheme.q1CoralRed,
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${appointment.alertStatus.label.toUpperCase()} • RE-PINGS EVERY ${appointment.repingIntervalMinutes}M',
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
                  label: const Text('Got It (Ack)'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      controller.snoozeAppointment(appointment, minutes: 10),
                  icon: const Icon(Icons.snooze_rounded, size: 16),
                  label: const Text('Snooze 10m'),
                ),
                TextButton.icon(
                  onPressed: () => controller.completeAppointment(appointment),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
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

    return Card(
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
              '$startsFormatted • ${appointment.leadMinutes}m lead • ${appointment.alertStatus.label}',
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
              child: Text('Trigger Escalation Ping Now'),
            ),
            PopupMenuItem(
              value: 'DONE',
              child: Text('Mark Completed'),
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
