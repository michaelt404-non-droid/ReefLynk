import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reeflynk/config/feature_flags.dart';
import 'package:reeflynk/services/auth_service.dart';
import 'package:reeflynk/providers/reef_controller_provider.dart';
import 'package:reeflynk/screens/manual_entry_screen.dart';
import 'package:reeflynk/screens/settings_screen.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/screens/charts_screen.dart';
import 'package:reeflynk/screens/sign_in_screen.dart';
import 'package:reeflynk/screens/lighting_screen.dart';
import 'package:reeflynk/screens/maintenance_screen.dart';
import 'package:reeflynk/screens/livestock_screen.dart';
import 'package:reeflynk/providers/lighting_provider.dart';
import 'package:reeflynk/services/notification_service.dart';
import 'package:reeflynk/services/maintenance_scheduler.dart';
import 'package:reeflynk/theme/app_theme.dart';
import 'package:reeflynk/screens/paywall_screen.dart';
import 'package:reeflynk/screens/reset_password_screen.dart';

// Global notifier so the recovery event is never missed regardless of when
// the widget tree subscribes.
final ValueNotifier<bool> passwordRecoveryNotifier = ValueNotifier(false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On web: detect recovery flow BEFORE Supabase processes the URL hash.
  if (kIsWeb) {
    final fragment = Uri.splitQueryString(Uri.base.fragment);
    final query = Uri.base.queryParameters;
    if (fragment['type'] == 'recovery' || query['type'] == 'recovery') {
      passwordRecoveryNotifier.value = true;
    }
  }

  await Supabase.initialize(
    url: 'https://ueeqgqqthiwcrvopdkft.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVlZXFncXF0aGl3Y3J2b3Bka2Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4OTkyMDAsImV4cCI6MjA4NTQ3NTIwMH0.dtQWdz87vhv2ZW0aLf-K4e1sucH8g82PHacJVmse7vw',
    authOptions: FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );

  // Listen for passwordRecovery events (handles mobile deep links and
  // any cases the pre-init URL check above doesn't catch).
  // Do NOT reset on signedIn — passwordRecoveryNotifier is only cleared
  // after the user successfully submits a new password.
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      passwordRecoveryNotifier.value = true;
    }
  });

  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) =>
              Supabase.instance.client.auth.onAuthStateChange.map((event) => event.session?.user),
          initialData: Supabase.instance.client.auth.currentUser,
        ),
        if (FeatureFlags.isControllerEnabled)
          ChangeNotifierProvider(create: (context) => ReefControllerProvider()),
    Provider<DatabaseService>(create: (_) => DatabaseService()),
    ChangeNotifierProxyProvider<DatabaseService, LightingProvider>(
            create: (context) => LightingProvider(),
            update: (context, dbService, previous) {
              previous?.updateDatabaseService(dbService);
              return previous ?? LightingProvider()..updateDatabaseService(dbService);
            },
          ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReefLynk',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: passwordRecoveryNotifier,
      builder: (context, isRecovery, _) {
        if (isRecovery) return const ResetPasswordScreen();

        final user = context.watch<User?>();
        final authService = context.read<AuthService>();

        if (user != null) {
          if (authService.isProUser) return const MainScreen();
          return const PaywallScreen();
        }
        return const SignInScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initNotificationsAndReschedule();
  }

  Future<void> _initNotificationsAndReschedule() async {
    await NotificationService().requestPermissions();
    // Reschedule all maintenance notifications on app open
    final db = Provider.of<DatabaseService>(context, listen: false);
    try {
      final tasks = await db.getMaintenanceTasksStream().first;
      final completions = await db.getLatestCompletions();
      await NotificationService().cancelAllReminders();
      for (final task in tasks) {
        if (task.id == null) continue;
        final lastCompletion = completions[task.id];
        final reminderTime =
            MaintenanceScheduler.getReminderTime(task, lastCompletion);
        await NotificationService().scheduleMaintenanceReminder(
          taskId: task.id!,
          taskName: task.name,
          scheduledDate: reminderTime,
        );
      }
    } catch (_) {
      // Silently fail — notifications are best-effort
    }
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const ManualEntryScreen(),
    const ChartsScreen(),
    const MaintenanceScreen(),
    const LivestockScreen(),
    if (FeatureFlags.isLightingEnabled) const LightingScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReefLynk'),
        actions: [
          if (FeatureFlags.isControllerEnabled)
            Consumer<ReefControllerProvider>(
              builder: (context, reefControllerProvider, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    reefControllerProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: reefControllerProvider.isConnected
                        ? AppColors.success
                        : AppColors.destructive,
                    size: 20,
                  ),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions.where((widget) => widget != null).toList().cast<Widget>()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Log Data',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Maint.',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Livestock',
          ),
          if (FeatureFlags.isLightingEnabled)
            NavigationDestination(
              icon: Icon(Icons.lightbulb_outline),
              selectedIcon: Icon(Icons.lightbulb),
              label: 'Lighting',
            ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
