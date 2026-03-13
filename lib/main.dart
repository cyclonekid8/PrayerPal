// lib/main.dart
import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/prayer_time_service.dart';
import 'services/permission_service.dart';
import 'screens/home_screen.dart';
import 'screens/timers_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PrayerTimeService().init();
  await NotificationService().init();

  runApp(const PrayerPalApp());
}

class PrayerPalApp extends StatelessWidget {
  const PrayerPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrayerPal',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080d16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFc8a84a),
          secondary: Color(0xFF2dd4bf),
          surface: Color(0xFF141d2b),
        ),
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TimersScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _runPermissionFlowThenSchedule();
    _listenToNotificationEvents();
  }

  Future<void> _runPermissionFlowThenSchedule() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await PermissionService().requestAllPermissions(context);
    }
    await _scheduleToday();
  }

  Future<void> _scheduleToday() async {
    final today = DateTime.now();
    await NotificationService().scheduleTestNotification();
    await NotificationService().scheduleDay(today);
    await NotificationService().scheduleDay(today.add(const Duration(days: 1)), dayOffset: 1);
  }

  void _listenToNotificationEvents() {
    NotificationEvents.openCamera.listen((payload) {
      // Navigate to camera screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const _CameraPlaceholder()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF0e1520),
        indicatorColor: const Color(0xFF1a2438),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mosque_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Timers'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Camera screen — implement with camera package')),
  );
}
