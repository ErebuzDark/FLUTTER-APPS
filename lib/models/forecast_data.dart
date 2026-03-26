class ForecastHour {
  final DateTime time;
  final double temp;
  final String icon;
  final String description;
  final double pop; // probability of precipitation (0.0 - 1.0)

  ForecastHour({
    required this.time,
    required this.temp,
    required this.icon,
    required this.description,
    required this.pop,
  });

  factory ForecastHour.fromJson(Map<String, dynamic> json) {
    return ForecastHour(
      time: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temp: (json['main']['temp'] as num).toDouble(),
      icon: json['weather'][0]['icon'] as String,
      description: json['weather'][0]['description'] as String,
      pop: (json['pop'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String icon;
  final String description;

  ForecastDay({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
    required this.description,
  });
}
