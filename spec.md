# Habit Tracker — Flutter App Spec

## 1. Overview

A mobile habit-tracking app built in Flutter. Users register, log in, create and manage daily habits, track streaks and progress, view reports, and receive optional notifications. The app also includes two supporting feature pages powered by free external APIs: a Motivation page (ZenQuotes) and a Weather page (Open-Meteo).

This spec translates the product backlog into concrete screens, data models, navigation, and API integrations for implementation.

---

## 2. Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** Provider or Riverpod (pick one; examples below assume Provider)
- **Local persistence:** `shared_preferences` (session/settings) + `sqflite` or `hive` (habits, history, streaks)
- **Networking:** `http` package
- **Navigation:** `go_router` (named routes, deep-linkable)
- **Notifications:** `flutter_local_notifications`
- **Charts:** `fl_chart` (for Reports page)

---

## 3. App Structure / Screens

| Screen | Route | Auth Required |
|---|---|---|
| Registration | `/register` | No |
| Login | `/login` | No |
| Homepage | `/home` | Yes |
| Settings Menu | `/menu` | Yes |
| Profile | `/profile` | Yes |
| Habits List | `/habits` | Yes |
| Habit Detail | `/habits/:id` | Yes |
| Reports | `/reports` | Yes |
| Notifications Settings | `/notifications` | Yes |
| Motivation | `/motivation` | Yes |
| Weather | `/weather` | Yes |

---

## 4. Data Models

```dart
class User {
  final String id;
  String name;
  String username;
  String passwordHash; // never store plain text
  int age;
  String country;
}

class Habit {
  final String id;
  String name;
  Color color;
  bool isOutdoor; // used for Weather-linked habits
  DateTime createdAt;
  List<HabitCompletion> completions;
}

class HabitCompletion {
  final DateTime date;
  final bool completed;
}

class NotificationSettings {
  bool enabled;
  List<String> habitIds; // habits opted in for notifications
  List<NotificationTime> times; // morning, afternoon, evening
}

enum NotificationTime { morning, afternoon, evening }
```

---

## 5. Screen Specs (mapped from backlog)

### 5.1 Registration (`/register`)
- Fields: name, username, age, country, password.
- Client-side validation: required fields, minimum age, username format.
- On submit: create `User`, persist locally, navigate to `/login` or auto-login to `/home`.
- **Source stories:** Account Registration.

### 5.2 Login (`/login`)
- Fields: username, password.
- On success: create session, navigate to `/home`.
- On failure: show inline error message ("Invalid username or password") without specifying which field was wrong.
- **Source stories:** Account Login, Error Feedback on Login.

### 5.3 Homepage (`/home`)
- Welcome header: `Welcome back, {name}`.
- Weekly progress summary widget (per-habit daily progress).
- Completed habits section (today's completed habits).
- Motivational quote preview card → tapping navigates to `/motivation`.
- **Source stories:** View Welcome Message, Display Weekly Progress, View Completed Habits, Display Quote on Homepage.

### 5.4 Settings Menu (`/menu`)
- Navigation list: Profile, Habits, Reports, Notifications, Sign Out.
- Sign Out clears session and navigates to `/login`.
- **Source stories:** Access Menu Options, Navigate to Profile, Navigate to Habits Page, Sign Out from Menu.

### 5.5 Profile (`/profile`)
- Displays name, username, age, country.
- Edit mode with save/cancel.
- Saving persists changes and updates the app header immediately (via state notifier).
- **Source stories:** View Personal Information, Edit Personal Information, Save Updated Information, Update Name in Header.

### 5.6 Habits List (`/habits`)
- List of all habits with color indicator and daily completion checkbox.
- Add Habit: form with name + color picker.
- Delete Habit: swipe-to-delete or button with confirmation dialog.
- Tapping a habit navigates to `/habits/:id`.
- **Source stories:** Add a New Habit, Delete a Habit, Personalize a Habit with Color.

### 5.7 Habit Detail (`/habits/:id`)
- Header: habit name, color, outdoor toggle.
- Current streak + longest streak display.
- History calendar/list view (completed vs. missed days).
- Edit (name/color) and Delete actions.
- If `isOutdoor == true`, show current weather snippet (from Weather API layer).
- **Source stories:** View Habit Details, View Habit Streak, View Habit History, Edit Habit from Detail Screen, Delete Habit from Detail Screen, Link Weather to Outdoor Habits.

### 5.8 Reports (`/reports`)
- Weekly summary report (per habit).
- Bar/line chart of completions per day (`fl_chart`), colored per habit.
- Toggle/filter: All / Completed / Incomplete.
- **Source stories:** View Weekly Reports, Visualize Completed Habits, View All Habits.

### 5.9 Notifications Settings (`/notifications`)
- Global enable/disable toggle.
- Multi-select list of habits to receive notifications for.
- Time selection: Morning / Afternoon / Evening (multi-select).
- Persists to `NotificationSettings` and schedules local notifications via `flutter_local_notifications`.
- **Source stories:** Enable/Disable Notifications, Add Habits for Notifications, Set Notification Times.

### 5.10 Motivation (`/motivation`)
- Fetches a random quote from ZenQuotes on load.
- Displays quote text + author.
- "Refresh" button fetches a new quote (debounced to respect rate limits).
- Fallback quote shown if API call fails.
- **Source stories:** View Daily Motivational Quote, Refresh Quote, Display Quote on Homepage.

### 5.11 Weather (`/weather`)
- Current weather for user's location (temperature, condition).
- 5–7 day forecast list.
- Requests location permission; falls back to manual location entry if denied.
- **Source stories:** View Current Weather, View Weekly Weather Forecast, Link Weather to Outdoor Habits.

---

## 6. External API Integrations

### 6.1 ZenQuotes API
- **Endpoint:** `GET https://zenquotes.io/api/random`
- **Auth:** None required.
- **Response shape:**
```json
[{ "q": "Quote text", "a": "Author", "h": "<html blockquote>" }]
```
- **Rate limit:** ~5 requests / 30 seconds (free tier). Cache the fetched quote (e.g., per day, in `shared_preferences`) rather than re-fetching on every screen visit.
- **Error handling:** On failure or timeout, display a bundled fallback quote list.

### 6.2 Open-Meteo API
- **Current + forecast endpoint:** `GET https://api.open-meteo.com/v1/forecast`
  - **Required params:** `latitude`, `longitude`
  - **Recommended params:** `current_weather=true`, `daily=temperature_2m_max,temperature_2m_min,weathercode`, `timezone=auto`
- **Auth:** None required.
- **Geocoding (if manual location entry needed):** Open-Meteo Geocoding API — `GET https://geocoding-api.open-meteo.com/v1/search?name={city}`
- **Location source:** Device GPS (via `geolocator` package) with permission prompt; fallback to manual city search via geocoding endpoint if denied.
- **Error handling:** Show a "weather unavailable" state; Habit Detail's weather snippet degrades gracefully (habit screen still fully functional without it).

---

## 7. Non-Functional Requirements

- **Security:** Passwords hashed before storage; never stored or logged in plain text.
- **Offline behavior:** Habit data (habits, completions, streaks) must work fully offline; Motivation and Weather pages should show cached/fallback data when offline.
- **Accessibility:** Sufficient color contrast for habit color-coding; don't rely on color alone to convey completion status (pair with icons/labels).
- **Performance:** Cache API responses (quotes daily, weather hourly) to minimize network calls and respect free-tier rate limits.

---

## 8. Priority Build Order (from backlog)

1. **High:** Registration, Login, Error Feedback on Login, Weekly Progress, Menu Access, Sign Out, Save Profile Info, Add Habit.
2. **Medium:** Welcome Message, Completed Habits section, Profile view/edit, Navigate to Profile/Habits, Delete Habit, Habit Detail (view/streak), Weekly/Visualized Reports, Notification enable + habit selection.
3. **Low:** Update Name in Header, Habit color personalization, View All Habits filter, Notification times, Habit History, Edit/Delete from Detail, Motivation page (all stories), Weather page (all stories).