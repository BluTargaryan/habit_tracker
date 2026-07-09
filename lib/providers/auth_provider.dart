import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../services/db_service.dart';
import '../utils/id_generator.dart';

class AuthProvider extends ChangeNotifier {
  static const _sessionUserIdKey = 'sessionUserId';

  final DbService _dbService;

  AuthProvider({DbService? dbService}) : _dbService = dbService ?? DbService.instance;

  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  Future<bool> register({
    required String name,
    required String username,
    required int age,
    required String country,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final user = User(
      id: generateId(),
      name: name.trim(),
      username: username.trim(),
      passwordHash: _hashPassword(password),
      age: age,
      country: country.trim(),
    );

    try {
      await _dbService.insertUser(user);
      isLoading = false;
      notifyListeners();
      return true;
    } on DatabaseException catch (e) {
      isLoading = false;
      errorMessage = e.isUniqueConstraintError()
          ? 'That username is already taken'
          : 'Could not create account. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final user = await _dbService.getUserByUsername(username.trim());
    final passwordMatches = user != null && user.passwordHash == _hashPassword(password);

    if (!passwordMatches) {
      isLoading = false;
      errorMessage = 'Invalid username or password';
      notifyListeners();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, user.id);

    currentUser = user;
    isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
    currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String username,
    required int age,
    required String country,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final updated = User(
      id: user.id,
      name: name.trim(),
      username: username.trim(),
      passwordHash: user.passwordHash,
      age: age,
      country: country.trim(),
    );

    try {
      await _dbService.updateUser(updated);
      currentUser = updated;
      isLoading = false;
      notifyListeners();
      return true;
    } on DatabaseException catch (e) {
      isLoading = false;
      errorMessage = e.isUniqueConstraintError()
          ? 'That username is already taken'
          : 'Could not save changes. Please try again.';
      notifyListeners();
      return false;
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
