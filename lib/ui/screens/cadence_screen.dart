import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cadence_goal.dart';
import '../../models/enums.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Routines Tab: Recurring habits and goals across 5 frequencies
/// (Daily, Every 2 Days, Weekly, Every 2 Weeks, Monthly) with solid cards
/// and warm human wording.
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
        // 1. Frequency Selector Strip
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
        const SizedBox(height: 14),

        // 2. Friendly Summary Header Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: CadenceFlowTheme.heroBannerDecoration(context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selectedHorizon.isIntervalBased
                      ? Icons.autorenew_rounded
                      : Icons.event_repeat_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedHorizon.label} Routines',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedHorizon.humanDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Routine Cards
        if (goals.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: CadenceFlowTheme.solidCardDecoration(context),
            child: Column(
              children: [
                Icon(Icons.repeat_rounded, size: 42, color: scheme.primary),
                const SizedBox(height: 10),
                Text(
                  'No ${selectedHorizon.label.toLowerCase()} routines yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap "Add Routine" below to start a new habit.',
                ),
              ],
            ),
          )
        else
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: goal.quadrant.color,
        highlighted: isDue,
      ),
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
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: goal.quadrant.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            goal.quadrant.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: goal.quadrant.color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CadenceFlowTheme.accentAmberLight
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 ${goal.streakCount} in a row',
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
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: CadenceFlowTheme.q1CoralRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DUE TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (goal.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.notes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete Routine',
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
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDue ? CadenceFlowTheme.accentAmberLight : scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT UP',
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
              FilledButton.icon(
                onPressed: () async {
                  final previous = await controller.completeCadenceCycle(goal);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Great job! "${goal.title}" is set for next time (🔥 ${goal.streakCount + 1})',
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
                label: const Text('Mark Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
