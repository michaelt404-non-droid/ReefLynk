import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'package:reeflynk/firebase_options.dart';
import 'package:reeflynk/services/auth_service.dart';
import 'package:reeflynk/providers/reef_controller_provider.dart';
import 'package:reeflynk/screens/dashboard_screen.dart';
import 'package:reeflynk/screens/settings_screen.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/screens/charts_screen.dart';
import 'package:reeflynk/screens/sign_in_screen.dart';
import 'package:reeflynk/screens/lighting_screen.dart';
import 'package:reeflynk/providers/lighting_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (context) => ReefControllerProvider()),
        ProxyProvider<User?, DatabaseService>(
          update: (context, user, previous) => DatabaseService(uid: user?.uid),
        ),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return const MainScreen();
    }
    return const SignInScreen();
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final ReefControllerProvider _reefControllerProvider;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    ChartsScreen(),
    const LightingScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _reefControllerProvider = context.read<ReefControllerProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reefControllerProvider.startDiscovery();
    });
  }

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
          Consumer<ReefControllerProvider>(
            builder: (context, reefControllerProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  reefControllerProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: reefControllerProvider.isConnected ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Charts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Lighting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}