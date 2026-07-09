class Validators {
  Validators._();

  static const int minAge = 16;
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (!_usernamePattern.hasMatch(value.trim())) {
      return 'Username must be 3-20 characters: letters, numbers, underscores only';
    }
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Age must be a number';
    }
    if (parsed < minAge) {
      return 'You must be at least $minAge to register';
    }
    return null;
  }

  static String? country(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  static String? habitName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Habit name is required';
    }
    return null;
  }
}
