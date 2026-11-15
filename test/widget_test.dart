import 'package:cadenceflow/data/local_storage_mirror.dart';
import 'package:cadenceflow/data/productivity_repository.dart';
import 'package:cadenceflow/main.dart';
import 'package:cadenceflow/services/clerk_auth_service.dart';
import 'package:cadenceflow/services/reminder_scheduler.dart';
import 'package:cadenceflow/state/productivity_controller.dart';
import 'package:cadenceflow/ui/widgets/brand_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'CadenceFlowApp renders ClerkAuthGate with brand icon, signs in, and navigates Matrix, Cadences & Alerts tabs',
      (WidgetTester tester) async {
    // Emulate an itel Power 70 tall mobile viewport (540 x 1200 logical px)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    // 1. Verify ClerkAuthGate welcome screen & custom CadenceFlowBrandIcon render
    expect(find.text('CadenceFlow'), findsOneWidget);
    expect(find.byType(CadenceFlowBrandIcon), findsOneWidget);
    expect(find.text('Sign in with Clerk'), findsOneWidget);

    // 2. Scroll to and tap "Start Immediately in Local Offline Workspace"
    final offlineButton =
        find.text('Start Immediately in Local Offline Workspace');
    await tester.ensureVisible(offlineButton);
    await tester.pumpAndSettle();
    await tester.tap(offlineButton);
    await tester.pumpAndSettle();

    // 3. Verify Today & Eisenhower Matrix screen + Top AppBar Brand Icon are active
    expect(find.byType(CadenceFlowBrandIcon), findsOneWidget);
    expect(find.text('Today\'s Execution Pulse'), findsOneWidget);
    expect(find.text('Q1 • Do First'), findsWidgets);

    // 4. Switch to Cadences tab
    final cadencesTab = find.text('Cadences').first;
    await tester.ensureVisible(cadencesTab);
    await tester.tap(cadencesTab);
    await tester.pumpAndSettle();
    expect(find.textContaining('Daily Horizon'), findsOneWidget);

    // 5. Switch to Alerts tab
    final alertsTab = find.text('Alerts').first;
    await tester.ensureVisible(alertsTab);
    await tester.tap(alertsTab);
    await tester.pumpAndSettle();
    expect(find.textContaining('Attention Feed'), findsOneWidget);
  });
}
