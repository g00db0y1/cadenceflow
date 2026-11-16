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
      'E2E: First-Startup Setup Wizard, Human Wording & App Guide, Solid UI, Calendar (Daily/Weekly/Monthly), Routines & Aggressive Reminders',
      (WidgetTester tester) async {
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
    await reminderScheduler.initialize();
    final controller = ProductivityController(
      repository: repository,
      reminderScheduler: reminderScheduler,
    );
    addTearDown(() => reminderScheduler.disposeAllTimers());

    await tester.pumpWidget(
      CadenceFlowApp(
        authService: authService,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Human-Friendly Welcome Screen & Brand Icon
    expect(find.text('CadenceFlow'), findsOneWidget);
    expect(find.byType(CadenceFlowBrandIcon), findsOneWidget);
    expect(find.text('Welcome to CadenceFlow'), findsOneWidget);

    // Enter workspace on this phone
    final offlineButton = find.text('Continue on This Phone');
    await tester.ensureVisible(offlineButton);
    await tester.pumpAndSettle();
    await tester.tap(offlineButton);
    await tester.pumpAndSettle();

    // 2. Verify First-Startup Guided Setup Wizard opens automatically
    expect(find.text('Quick Setup'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.textContaining('Tailor Your Day'), findsOneWidget);

    // Advance to Step 2 (Insistent Reminders & Permissions)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Never Miss an Important Reminder'), findsOneWidget);

    // Tap "Allow Notifications & Reminders" and "Send a Quick Test Reminder"
    await tester.tap(find.text('Allow Notifications & Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications & Alarms Enabled'), findsOneWidget);

    await tester.tap(find.text('Send a Quick Test Reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Test Reminder Triggered!'), findsOneWidget);

    // Advance to Step 3 and finish setup
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);

    await tester.tap(find.text('Finish Setup & Open App'));
    await tester.pumpAndSettle();

    // 3. Verify Focus Screen with Solid UI, Human Labels & Live Ringing Banner
    expect(find.byType(CadenceFlowBrandIcon), findsOneWidget);
    expect(find.text('Today\'s Progress'), findsOneWidget);
    expect(find.text('Do First'), findsWidgets);
    expect(find.text('Plan Ahead'), findsWidgets);
    expect(find.textContaining('Reminder Ringing'), findsOneWidget);

    // 4. Open Dedicated "How to Use CadenceFlow" Guide Section from AppBar
    final helpButton = find.byIcon(Icons.help_outline_rounded);
    await tester.tap(helpButton);
    await tester.pumpAndSettle();
    expect(find.text('How to Use CadenceFlow'), findsOneWidget);
    expect(
      find.text('1. Focus Tab — Sort by What Matters'),
      findsOneWidget,
    );
    expect(
      find.text('2. Calendar Tab — Daily, Weekly & Monthly Views'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // 5. Navigate to Calendar Tab and test Monthly, Weekly, and Daily views
    final calendarTab = find.text('Calendar').first;
    await tester.tap(calendarTab);
    await tester.pumpAndSettle();

    // Monthly view is active by default
    expect(find.text('Monthly').first, findsOneWidget);
    expect(find.textContaining('Overview for'), findsOneWidget);

    // Switch to Weekly view
    await tester.tap(find.text('Weekly').first);
    await tester.pumpAndSettle();
    expect(find.text('7-Day Workload Overview'), findsOneWidget);
    expect(find.text('Full Week Schedule'), findsOneWidget);

    // Switch to Daily view
    await tester.tap(find.text('Daily').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Morning Schedule (Before 12:00 PM)'),
      findsOneWidget,
    );
    expect(
      find.text('Afternoon Schedule (12:00 PM – 5:00 PM)'),
      findsOneWidget,
    );

    // 6. Navigate to Routines Tab
    final routinesTab = find.text('Routines').first;
    await tester.tap(routinesTab);
    await tester.pumpAndSettle();
    expect(find.text('Daily Routines'), findsOneWidget);
    expect(find.text('Mark Done'), findsWidgets);

    // 7. Navigate to Reminders Tab and verify Aggressive Reminders work
    final remindersTab = find.text('Reminders').first;
    await tester.tap(remindersTab);
    await tester.pumpAndSettle();
    expect(find.text('Insistent Reminders Are On'), findsOneWidget);
    expect(find.textContaining('Active Reminders'), findsOneWidget);

    // Trigger an escalation nudge and then acknowledge ("Got It")
    await tester.tap(find.text('Nudge Again'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ALERT #'), findsWidgets);

    final gotItButton = find.text('Got It').first;
    await tester.ensureVisible(gotItButton);
    await tester.tap(gotItButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Active Reminders (0)'), findsOneWidget);
  });
}
