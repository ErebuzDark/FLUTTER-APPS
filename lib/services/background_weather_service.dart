import 'package:flutter/material.dart';
import 'dart:ui';
import 'notification_service.dart';
import 'weather_service.dart';
import 'location_service.dart';

@pragma('vm:entry-point')
void hourlyWeatherTask() async {
  try {
    // Background isolates need initialized bindings
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // Initialize NotificationService to be able to show notifications
    await NotificationService.init();

    print('Background weather task running...');

    // Get city safely without triggering UI
    final String? city = await LocationService.getBackgroundCity();
    if (city == null) {
      print('Background location denied or unavailable.');
      return;
    }

    // Fetch the weather
    final weather = await WeatherService.fetch(city);

    // Show the notification
    await NotificationService.showWeatherNotification(
      city: weather.city,
      temperature: weather.temperature.round().toString(),
      description: weather.description,
    );

    print('Background weather task completed successfully.');
  } catch (e) {
    print('Background weather task failed: $e');
  }
}
