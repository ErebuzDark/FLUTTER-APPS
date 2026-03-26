import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/forecast_data.dart';

class WeatherService {
  static const String _apiKey = '438c72989e6c4fc808f8621c73495655';
  static const String _base =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastBase =
      'https://api.openweathermap.org/data/2.5/forecast';

  static Future<WeatherData> fetch(String city) async {
    final uri = Uri.parse('$_base?q=$city&appid=$_apiKey&units=metric');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('City "$city" not found.');
    } else {
      throw Exception('Something went wrong. Try again later.');
    }
  }

  static Future<WeatherData> fetchByLocation(double lat, double lon) async {
    final uri = Uri.parse('$_base?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather for location.');
    }
  }

  /// Fetches 5-day, 3-hourly forecast for a city name.
  /// Returns a list of [ForecastHour] (up to 40 entries = 5 days × 8 per day).
  static Future<List<ForecastHour>> fetchForecast(String city) async {
    final uri = Uri.parse('$_forecastBase?q=$city&appid=$_apiKey&units=metric&cnt=40');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>;
      return list.map((e) => ForecastHour.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Forecast unavailable.');
    }
  }

  /// Same as [fetchForecast] but uses GPS coordinates.
  static Future<List<ForecastHour>> fetchForecastByLocation(double lat, double lon) async {
    final uri = Uri.parse('$_forecastBase?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=40');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>;
      return list.map((e) => ForecastHour.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Forecast unavailable.');
    }
  }

  /// Groups hourly entries into daily summaries.
  static List<ForecastDay> groupByDay(List<ForecastHour> hours) {
    final Map<String, List<ForecastHour>> grouped = {};
    for (final h in hours) {
      final key = '${h.time.year}-${h.time.month}-${h.time.day}';
      grouped.putIfAbsent(key, () => []).add(h);
    }
    return grouped.entries.map((e) {
      final entries = e.value;
      final temps = entries.map((h) => h.temp).toList();
      // Use midday icon if available, otherwise first icon
      final midday = entries.firstWhere(
        (h) => h.time.hour >= 12 && h.time.hour <= 15,
        orElse: () => entries.first,
      );
      return ForecastDay(
        date: entries.first.time,
        minTemp: temps.reduce((a, b) => a < b ? a : b),
        maxTemp: temps.reduce((a, b) => a > b ? a : b),
        icon: midday.icon,
        description: midday.description,
      );
    }).toList();
  }
}