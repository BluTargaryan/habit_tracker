# CLAUDE.md — Habit Tracker (Flutter)

Guidance for Claude Code working in this repo. Full feature list and API details live in `spec.md` — treat it as the source of truth for scope.

## Project

Flutter habit-tracking app: registration/login, habit CRUD, streaks/history, reports, notifications, plus a combined Motivation & Weather page (ZenQuotes + Open-Meteo APIs).

## Tech Stack

- **State management:** Provider (`ChangeNotifier` + `ChangeNotifierProvider`). Don't introduce Riverpod, Bloc, or `setState`-heavy widgets for shared state.
- **Local storage:** sqflite. Habits, completions, and streak data persist here — not `shared_preferences` (reserve that for session/simple flags only).
- **Routing:** go_router, named routes.
- **HTTP:** `http` package.
- **Charts:** `fl_chart` (Reports page).
- **Notifications:** `flutter_local_notifications`.

## Folder Structure (layer-first)

```
lib/
  models/        # Habit, User, HabitCompletion, NotificationSettings
  screens/        # one file/folder per screen (login, home, habits, habit_detail, reports, notifications, motivation, profile)
                    # motivation/ covers the combined Motivation & Weather screen (/motivation) — no separate weather screen
  providers/       # ChangeNotifier classes (AuthProvider, HabitProvider, NotificationProvider, etc.)
  services/        # db_service.dart (sqflite), zenquotes_service.dart, weather_service.dart
  widgets/         # shared/reusable widgets (e.g. AppDrawer)
  utils/           # constants, formatters, validators
```

Mirror this under `test/` when tests are written (not now — see Testing below).

**Menu is a drawer, not a screen.** There's no `/menu` route or `MenuScreen` — the "Access Menu Options" story is implemented as `widgets/app_drawer.dart`, a shared `Drawer` attached via `Scaffold(drawer: const AppDrawer(), ...)` on every authenticated screen (Home, Habits, Profile, and future screens as they're built). Not attached on the auth screens (Register, Login). `spec.md` §3/§5.4 reflect this.

**Motivation and Weather are one screen.** There's no `/weather` route — both features live on `/motivation` as two sections of one scrollable screen (quote section, then weather section). `zenquotes_service.dart` and `weather_service.dart` stay separate service files (API concerns), but the UI and its provider(s) are combined. `spec.md` §5.10 and `product_backlog.md`'s "Motivation & Weather Page" section reflect this.

**Initial setup (already done, reference for future resets):** `lib/main.dart` was stripped of the default `flutter create` counter boilerplate down to a minimal `MaterialApp` with `Placeholder()` as `home` — real routing/screens replace this incrementally as they're built. The layer folders above were created empty ahead of any screen work, each with a `.gitkeep` so git tracks them before real files land; remove a folder's `.gitkeep` once it holds a real file.

## Conventions

- File names: `snake_case.dart`. Classes: `PascalCase`. Providers named `XProvider` (e.g. `HabitProvider`).
- One provider per domain concern — don't merge unrelated state into a single provider.
- Screens should be thin: pull data via `Consumer`/`context.watch`, delegate logic to providers/services.
- Keep API keys/config out of source — Open-Meteo and ZenQuotes need none, but don't hardcode anything that should be an env var later.

## Scope Discipline

- Implement only what's asked. If a prompt is for one screen or feature, don't also touch unrelated screens, providers, or files.
- If a request is ambiguous or would require assumptions (e.g. exact streak-reset rule, which fields are required), flag it rather than guessing silently.
- Don't add packages beyond the stack above without checking first.

## Testing

- **Not part of the build-out pass.** Write widget tests only when explicitly requested, as a separate step after a feature is working — not automatically alongside feature code.
- When tests are requested: use `flutter_test`, mirror `lib/` structure under `test/`, one test file per screen/provider.

## Commands

```
flutter pub get       # install deps
flutter run            # run app
flutter analyze        # lint
flutter test            # run tests (once they exist)
```

## Verification

- `sqflite` has no web support and needs `sqflite_common_ffi` (not in our stack) for desktop — always verify on Android/iOS, not Chrome/Windows.
- Claude does not launch the app or drive the emulator itself. After a feature is implemented and `flutter analyze` is clean, hand the user the exact commands to run and let them verify:
  ```
  flutter devices                    # confirm an Android emulator/device is available
  flutter emulators                  # list emulators if none are running
  flutter emulators --launch <id>    # start one
  flutter run -d <device-id>         # run and manually exercise the feature
  ```

## External APIs

- **ZenQuotes:** `GET https://zenquotes.io/api/random` — no auth. Cache result once per day; rate limit ~5 req/30s. Homepage's compact card and the full `/motivation` page both read the same cached quote — don't let each screen fetch independently.
- **Open-Meteo:** `GET https://api.open-meteo.com/v1/forecast?latitude=&longitude=&current_weather=true&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto` — no auth. Requires device location (via `geolocator`) or geocoded manual entry as fallback. Cache hourly; Homepage's compact card, the full `/motivation` page, and Habit Detail's outdoor-habit weather snippet all share the same cached current-weather data.

Full endpoint details, params, and error-handling expectations: see `spec.md` §6.

## Priority Order

Build in strict priority-tier order, from `spec.md` §9 (not §8's screen list, which only describes screen layout — it groups stories by screen, not by priority, and mixing the two causes stories from later tiers to get built early). All High-tier stories come before any Medium; all Medium before any Low. The tier is the unit of work, not the screen — a single screen's stories can span multiple tiers (e.g. Habits List bundles Add Habit [High], Delete Habit [Medium], and color personalization [Low]), so finishing "a screen" isn't the same as finishing a tier, and a screen may need revisiting once its later-tier stories come due.

1. **High:** Registration, Login, Error Feedback on Login, Weekly Progress (homepage), Menu Access, Sign Out, Save Profile Info, Add Habit.
2. **Medium:** Welcome Message (homepage), Completed Habits section (homepage), Profile view/edit, Navigate to Profile/Habits (menu), Delete Habit, Habit Detail (view/streak), Weekly/Visualized Reports, Notification enable + habit selection.
3. **Low:** Update Name in Header, Habit color personalization, View All Habits filter, Notification times, Habit History, Edit/Delete from Detail, Motivation & Weather page (all stories, both sections — see `spec.md` §5.10).

Some stories have hard dependencies that cut against strict tier order (e.g. Weekly Progress needs habit data that only exists once Add Habit — same tier — is built; a screen's route may need a placeholder destination for a not-yet-built later-tier screen it links to). Flag these when they come up rather than silently resolving them.

Work through this order one story at a time. On completing a story, stop and ask before starting the next one — don't chain straight into it. Example: after finishing registration (High), ask before starting login (High).