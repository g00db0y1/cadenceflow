import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cadence_goal.dart';
import '../../models/enums.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Cadences Tab: Dedicated 5-Tier Recurring Goal Planner.
/// - Segmented horizon selector: **Daily**, **Bi-Daily (2d)**, **Weekly (7d)**,
///   **Bi-Weekly (14d)**, and **Monthly**.
/// - Displays streak counters, cycle progress bars, next due timestamps, and
///   one-tap **Complete Cycle** rollover powered by `CadenceCalculator` with Undo.
class CadenceScreen extends StatelessWidget {
  const CadenceScreen({
    super.key,
    required this.controller,
  });

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final selectedHorizon = controller.selectedCadenceHorizon;
    final goals = controller.goalsForHorizon(selectedHorizon);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // 1. 5-Horizon Selector Strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CadenceType.values.map((horizon) {
              final isSelected = horizon == selectedHorizon;
              final count = controller.goalsForHorizon(horizon).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${horizon.label} ($count)'),
                  selected: isSelected,
                  onSelected: (_) => controller.setCadenceHorizon(horizon),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Hybrid Rollover Rule Banner for Selected Horizon
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selectedHorizon.isIntervalBased
                    ? Icons.autorenew_rounded
                    : Icons.event_repeat_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedHorizon.label} Horizon (${selectedHorizon.frequencyBadge})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedHorizon.isIntervalBased
                          ? 'Interval Rollover: Completing a cycle advances ${selectedHorizon.approximateDays}d from completion date so overdue items never pile up.'
                          : 'Calendar Anchor Rollover: Preserves your exact weekday/day-of-month schedule across cycles.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Cadence Goal Cards
        if (goals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(Icons.repeat_rounded, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    'No ${selectedHorizon.label} cadence goals yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap + to schedule a recurring goal for this horizon.',
                  ),
                ],
              ),
            ),
          )
        else
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CadenceGoalCard(
                goal: goal,
                controller: controller,
              ),
            ),
          ),
      ],
    );
  }
}

class _CadenceGoalCard extends StatelessWidget {
  const _CadenceGoalCard({
    required this.goal,
    required this.controller,
  });

  final CadenceGoal goal;
  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDue = goal.isDueTodayOrOverdue();
    final progress = goal.cycleProgress();
    final nextDueFormatted =
        DateFormat('EEE, MMM d • h:mm a').format(goal.nextDueDateTime);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  goal.quadrant.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              goal.quadrant.shortTag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: goal.quadrant.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: CadenceFlowTheme.accentAmberLight
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🔥 ${goal.streakCount}-cycle streak',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: CadenceFlowTheme.accentAmberLight,
                              ),
                            ),
                          ),
                          if (isDue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: CadenceFlowTheme.q1CoralRed
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DUE TODAY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: CadenceFlowTheme.q1CoralRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (goal.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.notes,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete Cadence Goal',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () => controller.deleteCadenceGoal(goal.id),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar across current cycle
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDue ? CadenceFlowTheme.accentAmberLight : scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT DUE CYCLE',
                        style: CadenceFlowTheme.monoStyle(
                          context,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextDueFormatted,
                        style: CadenceFlowTheme.monoStyle(
                          context,
                          fontSize: 12,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final previous =
                        await controller.completeCadenceCycle(goal);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Advanced "${goal.title}" to next ${goal.cadence.label.toLowerCase()} cycle (🔥 ${goal.streakCount + 1})',
                        ),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () =>
                              controller.restoreCadenceGoalState(previous),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Complete Cycle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
