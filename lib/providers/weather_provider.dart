import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  static const _latKey = 'weather.lat';
  static const _lonKey = 'weather.lon';
  static const _labelKey = 'weather.label';
  static const _snapshotKey = 'weather.snapshot';
  static const _fetchedAtKey = 'weather.fetchedAt';
  static const _cacheDuration = Duration(hours: 1);

  final WeatherService _service;
  final DateTime Function() _now;

  WeatherProvider({WeatherService? service, DateTime Function()? now})
      : _service = service ?? WeatherService(),
        _now = now ?? DateTime.now;

  WeatherSnapshot? snapshot;
  bool isLoading = false;
  String? errorMessage;
  String? locationLabel;

  /// True once we know device location is unavailable (denied/disabled) and
  /// no manual location has been saved yet — screen should offer city search.
  bool needsManualLocation = false;

  List<GeocodeResult> searchResults = [];
  bool isSearching = false;

  Future<void> loadIfNeeded() async {
    if (snapshot != null) return;

    final prefs = await SharedPreferences.getInstance();
    final fetchedAtStr = prefs.getString(_fetchedAtKey);
    final snapshotJson = prefs.getString(_snapshotKey);
    final lat = prefs.getDouble(_latKey);
    final lon = prefs.getDouble(_lonKey);

    if (fetchedAtStr != null && snapshotJson != null) {
      final fetchedAt = DateTime.parse(fetchedAtStr);
      if (_now().difference(fetchedAt) < _cacheDuration) {
        snapshot = WeatherSnapshot.fromMap(
          (jsonDecode(snapshotJson) as Map).cast<String, Object?>(),
        );
        locationLabel = prefs.getString(_labelKey);
        notifyListeners();
        return;
      }
    }

    if (lat != null && lon != null) {
      await _fetchAndCache(
        latitude: lat,
        longitude: lon,
        label: prefs.getString(_labelKey),
      );
      return;
    }

    await _useDeviceLocation();
  }

  Future<void> _useDeviceLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      needsManualLocation = true;
      isLoading = false;
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      needsManualLocation = true;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      await _fetchAndCache(
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Current Location',
      );
    } catch (_) {
      errorMessage = 'Weather unavailable.';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setManualLocation(GeocodeResult result) async {
    searchResults = [];
    final label = result.country != null ? '${result.name}, ${result.country}' : result.name;
    await _fetchAndCache(latitude: result.latitude, longitude: result.longitude, label: label);
    needsManualLocation = false;
  }

  Future<void> searchCity(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }

    isSearching = true;
    notifyListeners();

    try {
      searchResults = await _service.searchCity(query.trim());
    } catch (_) {
      searchResults = [];
    }

    isSearching = false;
    notifyListeners();
  }

  Future<void> _fetchAndCache({
    required double latitude,
    required double longitude,
    required String? label,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _service.fetchWeather(latitude: latitude, longitude: longitude);
      snapshot = fetched;
      locationLabel = label;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, latitude);
      await prefs.setDouble(_lonKey, longitude);
      if (label != null) await prefs.setString(_labelKey, label);
      await prefs.setString(_snapshotKey, jsonEncode(fetched.toMap()));
      await prefs.setString(_fetchedAtKey, _now().toIso8601String());
    } catch (_) {
      errorMessage = 'Weather unavailable.';
    }

    isLoading = false;
    notifyListeners();
  }
}
