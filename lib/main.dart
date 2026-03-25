import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/calendar_event.dart';
import 'services/notification_service.dart';
import 'screens/weather_screen.dart';
import 'screens/calendar_screen.dart';

void main() async {
  // Must be first line always
  WidgetsFlutterBinding.ensureInitialized();

  // Setup Hive local storage
  await Hive.initFlutter();
  Hive.registerAdapter(CalendarEventAdapter());
  await Hive.openBox<CalendarEvent>('events');

  // Setup notifications
  await NotificationService.init();
  await NotificationService.requestBatteryOptimizationExemption();

  // Start the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather & Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.dark,
        ),
      ),
      // Bottom navigation between Weather and Calendar
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WeatherScreen(),
    const CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E3A5F),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}