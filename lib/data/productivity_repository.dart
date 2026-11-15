import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/appointment.dart';
import '../models/cadence_goal.dart';
import '../models/task_item.dart';
import 'local_storage_mirror.dart';

/// Offline-first repository that persists all CRUD changes immediately to
/// [LocalStorageMirror] (for instant UI response and 100% offline alarm
/// reliability on the itel Power 70) and synchronizes with **Supabase
/// PostgreSQL** (`public.tasks`, `public.cadence_goals`, `public.appointments`)
/// whenever cloud credentials are configured.
class ProductivityRepository {
  ProductivityRepository({
    required this.localMirror,
    this.supabaseClient,
  });

  final LocalStorageMirror localMirror;
  final SupabaseClient? supabaseClient;

  bool get isCloudConnected =>
      AppConfig.isCloudSyncEnabled && supabaseClient != null;

  // ---------------------------------------------------------------------------
  // Tasks (Eisenhower Matrix)
  // ---------------------------------------------------------------------------

  Future<List<TaskItem>> fetchTasks(String userId) async {
    final localTasks = await localMirror.loadTasks(userId);
    if (!isCloudConnected) return localTasks;

    try {
      final rows = await supabaseClient!
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final remoteTasks = (rows as List<dynamic>)
          .map((r) => TaskItem.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (remoteTasks.isNotEmpty) {
        await localMirror.saveTasks(userId, remoteTasks);
        return remoteTasks;
      }
    } catch (e) {
      debugPrint('Supabase fetchTasks fallback to local mirror: $e');
    }
    return localTasks;
  }

  Future<void> upsertTask(String userId, TaskItem task) async {
    final current = await localMirror.loadTasks(userId);
    final idx = current.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      current[idx] = task;
    } else {
      current.insert(0, task);
    }
    await localMirror.saveTasks(userId, current);

    if (isCloudConnected) {
      try {
        await supabaseClient!.from('tasks').upsert(task.toMap());
      } catch (e) {
        debugPrint('Supabase upsertTask queued locally: $e');
      }
    }
  }

  Future<void> deleteTask(String userId, String taskId) async {
    final current = await localMirror.loadTasks(userId);
    current.removeWhere((t) => t.id == taskId);
    await localMirror.saveTasks(userId, current);

    if (isCloudConnected) {
      try {
        await supabaseClient!
            .from('tasks')
            .delete()
            .eq('id', taskId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('Supabase deleteTask queued locally: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cadence Goals (5-Tier Recurring Engine)
  // ---------------------------------------------------------------------------

  Future<List<CadenceGoal>> fetchCadenceGoals(String userId) async {
    final localGoals = await localMirror.loadCadenceGoals(userId);
    if (!isCloudConnected) return localGoals;

    try {
      final rows = await supabaseClient!
          .from('cadence_goals')
          .select()
          .eq('user_id', userId)
          .order('next_due_at_millis', ascending: true);
      final remoteGoals = (rows as List<dynamic>)
          .map((r) => CadenceGoal.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (remoteGoals.isNotEmpty) {
        await localMirror.saveCadenceGoals(userId, remoteGoals);
        return remoteGoals;
      }
    } catch (e) {
      debugPrint('Supabase fetchCadenceGoals fallback to local mirror: $e');
    }
    return localGoals;
  }

  Future<void> upsertCadenceGoal(String userId, CadenceGoal goal) async {
    final current = await localMirror.loadCadenceGoals(userId);
    final idx = current.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      current[idx] = goal;
    } else {
      current.add(goal);
    }
    await localMirror.saveCadenceGoals(userId, current);

    if (isCloudConnected) {
      try {
        await supabaseClient!.from('cadence_goals').upsert(goal.toMap());
      } catch (e) {
        debugPrint('Supabase upsertCadenceGoal queued locally: $e');
      }
    }
  }

  Future<void> deleteCadenceGoal(String userId, String goalId) async {
    final current = await localMirror.loadCadenceGoals(userId);
    current.removeWhere((g) => g.id == goalId);
    await localMirror.saveCadenceGoals(userId, current);

    if (isCloudConnected) {
      try {
        await supabaseClient!
            .from('cadence_goals')
            .delete()
            .eq('id', goalId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('Supabase deleteCadenceGoal queued locally: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Appointments (Social-Style Persistent Reminders)
  // ---------------------------------------------------------------------------

  Future<List<Appointment>> fetchAppointments(String userId) async {
    final localAppts = await localMirror.loadAppointments(userId);
    if (!isCloudConnected) return localAppts;

    try {
      final rows = await supabaseClient!
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('starts_at_millis', ascending: true);
      final remoteAppts = (rows as List<dynamic>)
          .map((r) => Appointment.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (remoteAppts.isNotEmpty) {
        await localMirror.saveAppointments(userId, remoteAppts);
        return remoteAppts;
      }
    } catch (e) {
      debugPrint('Supabase fetchAppointments fallback to local mirror: $e');
    }
    return localAppts;
  }

  Future<void> upsertAppointment(String userId, Appointment appointment) async {
    final current = await localMirror.loadAppointments(userId);
    final idx = current.indexWhere((a) => a.id == appointment.id);
    if (idx >= 0) {
      current[idx] = appointment;
    } else {
      current.add(appointment);
    }
    current.sort((a, b) => a.startsAtMillis.compareTo(b.startsAtMillis));
    await localMirror.saveAppointments(userId, current);

    if (isCloudConnected) {
      try {
        await supabaseClient!.from('appointments').upsert(appointment.toMap());
      } catch (e) {
        debugPrint('Supabase upsertAppointment queued locally: $e');
      }
    }
  }

  Future<void> deleteAppointment(String userId, String appointmentId) async {
    final current = await localMirror.loadAppointments(userId);
    current.removeWhere((a) => a.id == appointmentId);
    await localMirror.saveAppointments(userId, current);

    if (isCloudConnected) {
      try {
        await supabaseClient!
            .from('appointments')
            .delete()
            .eq('id', appointmentId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('Supabase deleteAppointment queued locally: $e');
      }
    }
  }
}
