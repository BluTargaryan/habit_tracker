import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather.dart';

class WeatherService {
  static const _forecastEndpoint = 'https://api.open-meteo.com/v1/forecast';
  static const _geocodingEndpoint = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<WeatherSnapshot> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastEndpoint).replace(queryParameters: {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current_weather': 'true',
      'daily': 'temperature_2m_max,temperature_2m_min,weathercode',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo request failed with status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final currentJson = decoded['current_weather'] as Map<String, dynamic>;
    final current = CurrentWeather(
      temperature: (currentJson['temperature'] as num).toDouble(),
      weatherCode: currentJson['weathercode'] as int,
    );

    final dailyJson = decoded['daily'] as Map<String, dynamic>;
    final dates = (dailyJson['time'] as List<dynamic>).cast<String>();
    final maxTemps = (dailyJson['temperature_2m_max'] as List<dynamic>).cast<num>();
    final minTemps = (dailyJson['temperature_2m_min'] as List<dynamic>).cast<num>();
    final codes = (dailyJson['weathercode'] as List<dynamic>).cast<int>();

    final daily = List.generate(dates.length, (i) {
      return DailyForecast(
        date: DateTime.parse(dates[i]),
        maxTemp: maxTemps[i].toDouble(),
        minTemp: minTemps[i].toDouble(),
        weatherCode: codes[i],
      );
    });

    return WeatherSnapshot(current: current, daily: daily);
  }

  Future<List<GeocodeResult>> searchCity(String query) async {
    final uri = Uri.parse(_geocodingEndpoint).replace(queryParameters: {'name': query});
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Geocoding request failed with status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>?;
    if (results == null) return [];

    return results.map((result) {
      final map = result as Map<String, dynamic>;
      return GeocodeResult(
        name: map['name'] as String,
        country: map['country'] as String?,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    }).toList();
  }
}
