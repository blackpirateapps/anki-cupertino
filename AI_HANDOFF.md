# AI Handoff

## Project Summary

This repository contains a Flutter Pomodoro app with a deliberately Cupertino-only interface. The app is implemented almost entirely in `lib/main.dart` and persists state locally with `shared_preferences`.

The repo does not check in generated platform folders. GitHub Actions recreates the Android host project before analysis and release APK build.

## Current Behavior

- Timer modes: focus, short break, long break
- Project selection with per-project colors
- Project creation, editing, and deletion
- Session completion tracking
- Daily and weekly minute summaries
- Seven-day chart and top-project ranking
- Local JSON persistence via a single app-state blob in `shared_preferences`

## Repository Layout

- `lib/main.dart`: app UI, timer logic, models, persistence, and stats
- `pubspec.yaml`: Flutter package metadata and dependencies
- `.github/workflows/build-release-apk.yml`: CI workflow that generates Android scaffolding, analyzes, and builds the release APK
- `README.md`: high-level project and build notes
- `AGENTS.md`: instructions for future AI contributors

## Important Constraints

- Keep the app Cupertino-themed. Do not introduce Material widgets or Android-native styling.
- The generated `android/` directory is intentionally excluded from version control.
- The release build path assumed by CI is `build/app/outputs/flutter-apk/app-release.apk`.
- Local Flutter tooling may not exist on this machine; CI is the source of truth for analysis and APK generation.

## Known Technical Debt

- The app is currently a single-file implementation. Splitting models, persistence, and UI into separate files would improve maintainability.
- There are no automated widget or unit tests yet.
- There is no notification/alarm behavior when a session completes.
- State persistence is intentionally simple and does not handle migrations beyond a single storage key.

## Recommended Next Steps

1. Add tests around state transitions and statistics calculations.
2. Split `lib/main.dart` into smaller feature-focused files once behavior stabilizes.
3. Add configurable timer lengths in the UI if customization is needed.
4. Consider exporting history or backup/import if persistence needs grow.

