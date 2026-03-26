import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/calendar_event.dart';
import 'models/expense.dart';
import 'models/budget.dart';
import 'models/deduction.dart';
import 'services/notification_service.dart';
import 'services/background_weather_service.dart';
import 'screens/weather_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/expense_screen.dart';

void main() async {
  // Must be first line always
  WidgetsFlutterBinding.ensureInitialized();

  // Setup Hive local storage
  await Hive.initFlutter();
  Hive.registerAdapter(CalendarEventAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(DeductionAdapter());
  await Hive.openBox<CalendarEvent>('events');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Budget>('budget');
  await Hive.openBox<Deduction>('deductions');

  // Setup notifications
  await NotificationService.init();
  await NotificationService.scheduleMonthlyExpenseReminders();

  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();

  // Schedule the hourly weather task
  await AndroidAlarmManager.periodic(
    const Duration(
      hours: 1,
    ), // <-- CHANGE THIS TO ALTER WEATHER NOTIFICATION FREQUENCY
    101, // arbitrary fixed ID
    hourlyWeatherTask,
    wakeup: true,
    exact: true,
    rescheduleOnReboot: false,
  );

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
    const ExpenseScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request notification and alarm permissions
    await NotificationService.requestPermissions();
    // Request battery optimization exemption first
    await NotificationService.requestBatteryOptimizationExemption();
    // Request location permissions for background execution
    if (await Permission.location.request().isGranted) {
      await Permission.locationAlways.request();
    }
  }

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
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Expenses'),
        ],
      ),
    );
  }
}
