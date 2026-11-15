import 'package:cadenceflow/data/local_storage_mirror.dart';
import 'package:cadenceflow/data/productivity_repository.dart';
import 'package:cadenceflow/main.dart';
import 'package:cadenceflow/services/clerk_auth_service.dart';
import 'package:cadenceflow/services/reminder_scheduler.dart';
import 'package:cadenceflow/state/productivity_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'CadenceFlowApp renders ClerkAuthGate, signs in, and navigates Matrix, Cadences & Alerts tabs',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final authService = ClerkAuthService();
    await authService.initialize();

    final localMirror = LocalStorageMirror();
    final repository = ProductivityRepository(localMirror: localMirror);
    final reminderScheduler = ReminderScheduler();
    final controller = ProductivityController(
      repository: repository,
      reminderScheduler: reminderScheduler,
    );

    await tester.pumpWidget(
      CadenceFlowApp(
        authService: authService,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify ClerkAuthGate welcome screen renders
    expect(find.text('CadenceFlow'), findsOneWidget);
    expect(find.text('Sign in with Clerk'), findsOneWidget);

    // 2. Tap "Start Immediately in Local Offline Workspace"
    await tester.tap(
      find.text('Start Immediately in Local Offline Workspace'),
    );
    await tester.pumpAndSettle();

    // 3. Verify Today & Eisenhower Matrix screen is active
    expect(find.text('Today\'s Execution Pulse'), findsOneWidget);
    expect(find.text('Q1 • Do First'), findsWidgets);

    // 4. Switch to Cadences tab
    await tester.tap(find.byIcon(Icons.repeat_outlined).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Daily Horizon'), findsOneWidget);

    // 5. Switch to Alerts tab
    await tester.tap(find.text('Alerts').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Attention Feed'), findsOneWidget);
  });
}
