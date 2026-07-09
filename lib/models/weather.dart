class CurrentWeather {
  final double temperature;
  final int weatherCode;

  const CurrentWeather({required this.temperature, required this.weatherCode});

  Map<String, Object?> toMap() {
    return {'temperature': temperature, 'weatherCode': weatherCode};
  }

  factory CurrentWeather.fromMap(Map<String, Object?> map) {
    return CurrentWeather(
      temperature: (map['temperature'] as num).toDouble(),
      weatherCode: map['weatherCode'] as int,
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });

  Map<String, Object?> toMap() {
    return {
      'date': date.toIso8601String(),
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'weatherCode': weatherCode,
    };
  }

  factory DailyForecast.fromMap(Map<String, Object?> map) {
    return DailyForecast(
      date: DateTime.parse(map['date'] as String),
      maxTemp: (map['maxTemp'] as num).toDouble(),
      minTemp: (map['minTemp'] as num).toDouble(),
      weatherCode: map['weatherCode'] as int,
    );
  }
}

class WeatherSnapshot {
  final CurrentWeather current;
  final List<DailyForecast> daily;

  const WeatherSnapshot({required this.current, required this.daily});

  Map<String, Object?> toMap() {
    return {
      'current': current.toMap(),
      'daily': daily.map((day) => day.toMap()).toList(),
    };
  }

  factory WeatherSnapshot.fromMap(Map<String, Object?> map) {
    return WeatherSnapshot(
      current: CurrentWeather.fromMap(map['current'] as Map<String, Object?>),
      daily: (map['daily'] as List<dynamic>)
          .map((day) => DailyForecast.fromMap((day as Map).cast<String, Object?>()))
          .toList(),
    );
  }
}

class GeocodeResult {
  final String name;
  final String? country;
  final double latitude;
  final double longitude;

  const GeocodeResult({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

/// WMO weather interpretation codes: https://open-meteo.com/en/docs
String describeWeatherCode(int code) {
  switch (code) {
    case 0:
      return 'Clear sky';
    case 1:
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Overcast';
    case 45:
    case 48:
      return 'Fog';
    case 51:
    case 53:
    case 55:
      return 'Drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
    case 63:
    case 65:
      return 'Rain';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
    case 73:
    case 75:
      return 'Snow fall';
    case 77:
      return 'Snow grains';
    case 80:
    case 81:
    case 82:
      return 'Rain showers';
    case 85:
    case 86:
      return 'Snow showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Thunderstorm with hail';
    default:
      return 'Unknown';
  }
}
