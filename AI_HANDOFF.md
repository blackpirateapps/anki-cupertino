# AI Handoff

## Project Summary

This repository contains a Flutter Pomodoro app with a deliberately Cupertino-only interface. The app now uses a small multi-file structure with a controller, models, storage service, and tab-specific UI files. State persists locally with `shared_preferences`.

The repo does not check in generated platform folders. GitHub Actions recreates the Android host project before analysis and release APK build.

## Current Behavior

- Timer modes: focus, short break, long break
- Running timer survives tab changes, app backgrounding, and app removal from recents by persisting wall-clock end time
- Project selection with per-project colors
- Project creation, editing, and deletion
- Confirmation dialogs for timer reset and project deletion
- Adjustable timer durations from the focus screen and from settings
- Session completion tracking
- Daily and weekly minute summaries
- Seven-day chart and top-project ranking
- Settings tab with import/export of a full JSON snapshot
- Local JSON persistence via a v2 snapshot that stores both app data and timer state, with fallback migration from the old v1 app-state blob

## Repository Layout

- `lib/main.dart`: entrypoint and `PomodoroApp` export
- `lib/app/app.dart`: top-level Cupertino app
- `lib/controllers/pomodoro_controller.dart`: timer logic, state mutations, persistence coordination, and statistics helpers
- `lib/models/`: app, timer, project, and persistence models
- `lib/services/app_storage.dart`: `shared_preferences` read/write and legacy fallback
- `lib/screens/`: tab UI and main shell
- `lib/widgets/`: shared presentational widgets
- `pubspec.yaml`: Flutter package metadata and dependencies
- `.github/workflows/build-release-apk.yml`: CI workflow that generates Android scaffolding, analyzes, and builds the release APK
- `README.md`: high-level project and build notes
- `AGENTS.md`: instructions for future AI contributors

## Important Constraints

- Keep the app Cupertino-themed. Do not introduce Material widgets or Android-native styling.
- The generated `android/` directory is intentionally excluded from version control.
- The release build path assumed by CI is `build/app/outputs/flutter-apk/app-release.apk`.
- Local Flutter tooling may not exist on this machine; CI is the source of truth for analysis and APK generation.
- Timer persistence depends on storing an absolute end timestamp, not just decrementing an in-memory counter.

## Known Technical Debt

- Test coverage is still minimal and currently limited to a basic widget smoke test.
- There is no notification/alarm behavior when a session completes.
- Import/export currently uses JSON text and clipboard flows, not file pickers.
- The focus screen and settings screen both mutate the same duration defaults, which is intentional but should be kept consistent if the UX changes.

## Recommended Next Steps

1. Add tests around state transitions and statistics calculations.
2. Add local notifications so session completion is visible while the app is backgrounded.
3. Consider file-based import/export if text-based backup becomes too awkward.
4. Add more targeted widget tests for settings, import/export validation, and resume-after-close timer behavior.
