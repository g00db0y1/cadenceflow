import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'data/local_storage_mirror.dart';
import 'data/productivity_repository.dart';
import 'services/clerk_auth_service.dart';
import 'services/reminder_scheduler.dart';
import 'state/productivity_controller.dart';
import 'theme/app_theme.dart';
import 'ui/screens/auth_gate_screen.dart';
import 'ui/screens/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = ClerkAuthService();
  await authService.initialize();

  // Initialize Supabase with Clerk Third-Party Auth JWT callback when configured.
  SupabaseClient? supabaseClient;
  if (AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        accessToken: authService.getSupabaseAccessToken,
      );
      supabaseClient = Supabase.instance.client;
    } catch (e) {
      debugPrint('Supabase init skipped (using offline mirror): $e');
    }
  }

  final localMirror = LocalStorageMirror();
  final repository = ProductivityRepository(
    localMirror: localMirror,
    supabaseClient: supabaseClient,
  );

  final reminderScheduler = ReminderScheduler();
  await reminderScheduler.initialize();

  final controller = ProductivityController(
    repository: repository,
    reminderScheduler: reminderScheduler,
  );

  if (authService.currentUser != null) {
    await controller.bindUserAndHydrate(authService.currentUser!.id);
  }

  runApp(
    CadenceFlowApp(
      authService: authService,
      controller: controller,
    ),
  );
}

class CadenceFlowApp extends StatefulWidget {
  const CadenceFlowApp({
    super.key,
    required this.authService,
    required this.controller,
  });

  final ClerkAuthService authService;
  final ProductivityController controller;

  @override
  State<CadenceFlowApp> createState() => _CadenceFlowAppState();
}

class _CadenceFlowAppState extends State<CadenceFlowApp> {
  String? _boundUserId;

  @override
  void initState() {
    super.initState();
    _boundUserId = widget.authService.currentUser?.id;
    widget.authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final newUserId = widget.authService.currentUser?.id;
    if (newUserId != null && newUserId != _boundUserId) {
      _boundUserId = newUserId;
      widget.controller.bindUserAndHydrate(newUserId);
    } else if (newUserId == null) {
      _boundUserId = null;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.authService, widget.controller]),
      builder: (context, _) {
        return MaterialApp(
          title: 'CadenceFlow',
          debugShowCheckedModeBanner: false,
          theme: CadenceFlowTheme.lightTheme(),
          darkTheme: CadenceFlowTheme.darkTheme(),
          themeMode: widget.controller.themeMode,
          home: widget.authService.isAuthenticated
              ? MainScaffold(
                  authService: widget.authService,
                  controller: widget.controller,
                )
              : ClerkAuthGateScreen(authService: widget.authService),
        );
      },
    );
  }
}
