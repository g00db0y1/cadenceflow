import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/enums.dart';
import '../../models/task_item.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';

/// Focus Tab: Priority Board & Daily Action List with solid, tactile cards
/// and warm human-friendly language.
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
        // 1. Solid Hero Summary Card (Today's Progress + Active Reminder Badge)
        _buildTopSummaryCard(context, scheme, urgentCount),
        const SizedBox(height: 16),

        // 2. View Mode Toggle (Priority Board vs Action List)
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.dashboard_rounded, size: 18),
                    label: Text('Priority Board'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.format_list_bulleted_rounded, size: 18),
                    label: Text('Action List'),
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

        // Quick Priority Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Tasks'),
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
        const SizedBox(height: 16),

        // 3. Main Content: Priority Board OR Ranked Action List
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
    final dueRoutines =
        controller.cadenceGoals.where((g) => g.isDueTodayOrOverdue()).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: CadenceFlowTheme.heroBannerDecoration(context),
      child: Row(
        children: [
          // Today's Progress Ring
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 6.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    CadenceFlowTheme.accentAmberDark,
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}%',
                  style: CadenceFlowTheme.monoStyle(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of $total tasks done • $dueRoutines routine${dueRoutines == 1 ? '' : 's'} due today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
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
                  color: CadenceFlowTheme.q1CoralRed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$urgentCount Alert${urgentCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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

        return Column(
          children: quadrants
              .map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
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
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: CadenceFlowTheme.solidCardDecoration(context),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 42),
            const SizedBox(height: 10),
            Text(
              'No tasks in this view right now',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('Tap "Add Task" below to add something new.'),
          ],
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

    return Container(
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        accentColor: quadrant.color,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: quadrant.color.withValues(alpha: 0.14),
              border: Border(
                left: BorderSide(color: quadrant.color, width: 6),
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
                            quadrant.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: quadrant.color),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: quadrant.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${activeTasks.length} open',
                              style: CadenceFlowTheme.monoStyle(
                                context,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
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
                'All clear here — no tasks waiting.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
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
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: CadenceFlowTheme.tactileTileDecoration(
        context,
        accentColor: task.quadrant.color,
        isCompleted: task.isCompleted,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                      : 'Done: "${task.title}"',
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
                      color: task.quadrant.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.quadrant.title,
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
          tooltip: 'Change Priority or Delete',
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
              child: Text('Move to Priority Group'),
            ),
            ...EisenhowerQuadrant.values.map(
              (q) => PopupMenuItem<String>(
                value: q.dbValue,
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: q.color, radius: 6),
                    const SizedBox(width: 8),
                    Text(q.title),
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
