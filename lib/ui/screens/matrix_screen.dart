import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/enums.dart';
import '../../models/task_item.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Home Tab: Today & Eisenhower Matrix Screen.
/// - Top summary strip with Today's completion ring, social-feed style urgent
///   reminder badge counter, and quick quadrant filter chips.
/// - Seamless toggle between **2x2 Matrix Grid View** and **Priority Queue View**
///   (sorted Q1 -> Q2 -> Q3 -> Q4).
class MatrixScreen extends StatelessWidget {
  const MatrixScreen({
    super.key,
    required this.controller,
    required this.onNavigateToAlerts,
  });

  final ProductivityController controller;
  final VoidCallback onNavigateToAlerts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgentCount = controller.urgentAttentionCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // 1. Top Summary Strip (Completion Ring + Urgent Ping Counter)
        _buildTopSummaryCard(context, scheme, urgentCount),
        const SizedBox(height: 14),

        // 2. View Mode Toggle (2x2 Matrix Grid vs Priority Queue) & Filter Chips
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.grid_view_rounded, size: 18),
                    label: Text('2×2 Matrix'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.format_list_numbered_rounded, size: 18),
                    label: Text('Priority Queue'),
                  ),
                ],
                selected: {controller.isPriorityQueueView},
                onSelectionChanged: (selection) {
                  controller.setPriorityQueueView(selection.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quick Quadrant Filter Chips (when in Priority Queue or inspecting)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Quadrants'),
                selected: controller.selectedQuadrantFilter == null,
                onSelected: (_) => controller.setQuadrantFilter(null),
              ),
              const SizedBox(width: 8),
              ...EisenhowerQuadrant.values.map((q) {
                final isSelected = controller.selectedQuadrantFilter == q;
                final activeCount = controller
                    .tasksForQuadrant(q)
                    .where((t) => !t.isCompleted)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: CircleAvatar(
                      backgroundColor: q.color,
                      radius: 6,
                    ),
                    label: Text('${q.title} ($activeCount)'),
                    selected: isSelected,
                    onSelected: (_) {
                      controller.setQuadrantFilter(q);
                      if (!controller.isPriorityQueueView) {
                        controller.setPriorityQueueView(true);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Main Content: 2x2 Grid OR Ranked Priority Queue
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: controller.isPriorityQueueView
              ? _buildPriorityQueueList(context)
              : _buildTwoByTwoGrid(context),
        ),
      ],
    );
  }

  Widget _buildTopSummaryCard(
    BuildContext context,
    ColorScheme scheme,
    int urgentCount,
  ) {
    final completed = controller.completedTasksCount;
    final total = controller.totalTasksCount;
    final ratio = controller.todayCompletionRatio;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Today's Completion Ring
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 6,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: CadenceFlowTheme.monoStyle(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Execution Pulse',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completed of $total tasks completed • ${controller.cadenceGoals.where((g) => g.isDueTodayOrOverdue()).length} cadences due',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (urgentCount > 0)
              InkWell(
                onTap: onNavigateToAlerts,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CadenceFlowTheme.q1CoralRed.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CadenceFlowTheme.q1CoralRed.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: CadenceFlowTheme.q1CoralRed,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$urgentCount Ping${urgentCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: CadenceFlowTheme.q1CoralRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoByTwoGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        const quadrants = EisenhowerQuadrant.values;

        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuadrantCard(
                      quadrant: quadrants[0],
                      tasks: controller.tasksForQuadrant(quadrants[0]),
                      controller: controller,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuadrantCard(
                      quadrant: quadrants[1],
                      tasks: controller.tasksForQuadrant(quadrants[1]),
                      controller: controller,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuadrantCard(
                      quadrant: quadrants[2],
                      tasks: controller.tasksForQuadrant(quadrants[2]),
                      controller: controller,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuadrantCard(
                      quadrant: quadrants[3],
                      tasks: controller.tasksForQuadrant(quadrants[3]),
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Compact phone 2x2 summary grid + expandable cards (itel Power 70 friendly)
        return Column(
          children: quadrants
              .map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuadrantCard(
                    quadrant: q,
                    tasks: controller.tasksForQuadrant(q),
                    controller: controller,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPriorityQueueList(BuildContext context) {
    final queue = controller.rankedPriorityQueue;
    if (queue.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 42),
              const SizedBox(height: 10),
              Text(
                'No tasks in this quadrant filter',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text('Tap + below to capture a new task or goal.'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: queue
          .map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskTile(
                task: task,
                controller: controller,
                showQuadrantBadge: true,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuadrantCard extends StatelessWidget {
  const _QuadrantCard({
    required this.quadrant,
    required this.tasks,
    required this.controller,
  });

  final EisenhowerQuadrant quadrant;
  final List<TaskItem> tasks;
  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: quadrant.color.withValues(alpha: 0.11),
              border: Border(
                left: BorderSide(color: quadrant.color, width: 5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            quadrant.shortTag,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: quadrant.color),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: quadrant.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${activeTasks.length} active',
                              style: CadenceFlowTheme.monoStyle(
                                context,
                                fontSize: 11,
                                color: quadrant.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${quadrant.subtitle} • ${quadrant.actionHint}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Clear quadrant — no tasks queued.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ...activeTasks.map(
                    (t) => _TaskTile(
                      task: t,
                      controller: controller,
                      showQuadrantBadge: false,
                    ),
                  ),
                  ...completedTasks.take(2).map(
                        (t) => _TaskTile(
                          task: t,
                          controller: controller,
                          showQuadrantBadge: false,
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.controller,
    required this.showQuadrantBadge,
  });

  final TaskItem task;
  final ProductivityController controller;
  final bool showQuadrantBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dueText = task.dueAtMillis != null
        ? DateFormat('MMM d, h:mm a')
            .format(DateTime.fromMillisecondsSinceEpoch(task.dueAtMillis!))
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Checkbox(
          value: task.isCompleted,
          activeColor: task.quadrant.color,
          onChanged: (_) async {
            await controller.toggleTaskCompleted(task);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  task.isCompleted
                      ? 'Reopened "${task.title}"'
                      : 'Completed "${task.title}"',
                ),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () => controller.toggleTaskCompleted(
                    task.copyWith(isCompleted: !task.isCompleted),
                  ),
                ),
              ),
            );
          },
        ),
        title: Text(
          task.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? scheme.onSurfaceVariant : null,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.notes.isNotEmpty)
              Text(
                task.notes,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (showQuadrantBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: task.quadrant.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.quadrant.shortTag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: task.quadrant.color,
                      ),
                    ),
                  ),
                if (dueText != null)
                  Text(
                    dueText,
                    style: CadenceFlowTheme.monoStyle(
                      context,
                      fontSize: 11,
                      color: task.isOverdue
                          ? CadenceFlowTheme.q1CoralRed
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                if (task.isPersistentAlert)
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 14,
                    color: CadenceFlowTheme.accentAmberLight,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Switch Quadrant or Delete',
          onSelected: (value) {
            if (value == 'DELETE') {
              controller.deleteTask(task.id);
              return;
            }
            final targetQuadrant = EisenhowerQuadrant.fromDb(value);
            controller.moveTaskQuadrant(task, targetQuadrant);
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('Move to Quadrant'),
            ),
            ...EisenhowerQuadrant.values.map(
              (q) => PopupMenuItem<String>(
                value: q.dbValue,
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: q.color, radius: 6),
                    const SizedBox(width: 8),
                    Text(q.shortTag),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'DELETE',
              child: Text(
                'Delete Task',
                style: TextStyle(color: CadenceFlowTheme.q1CoralRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
