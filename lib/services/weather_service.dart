import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart'; // we'll create this next

class WeatherService {
  static const String _apiKey = '438c72989e6c4fc808f8621c73495655';
  static const String _base =
      'https://api.openweathermap.org/data/2.5/weather';

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
}