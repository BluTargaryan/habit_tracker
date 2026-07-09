enum NotificationTime {
  morning,
  afternoon,
  evening;

  String get label {
    switch (this) {
      case NotificationTime.morning:
        return 'Morning';
      case NotificationTime.afternoon:
        return 'Afternoon';
      case NotificationTime.evening:
        return 'Evening';
    }
  }
}

class NotificationSettings {
  bool enabled;
  List<String> habitIds;
  List<NotificationTime> times;

  NotificationSettings({
    this.enabled = false,
    List<String>? habitIds,
    List<NotificationTime>? times,
  })  : habitIds = habitIds ?? [],
        times = times ?? [];
}
