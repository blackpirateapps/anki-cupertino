# Anki Cupertino

A lightweight Cupertino-themed Pomodoro app built with Flutter.

## Features

- Pure Cupertino UI
- Project-based focus sessions
- Daily and weekly statistics
- Persistent local storage with `shared_preferences`
- GitHub Actions workflow that builds a release APK artifact

## Build

The repository is intentionally kept small and does not check in the generated `android/` directory. GitHub Actions recreates the Android scaffold before building:

1. Install Flutter
2. Run `flutter create --platforms android .`
3. Run `flutter pub get`
4. Run `flutter analyze`
5. Run `flutter build apk --release`

The release APK is uploaded as a workflow artifact on pushes to `main` and on manual dispatch.

## AI Docs

- [AI_HANDOFF.md](AI_HANDOFF.md) captures the current repo structure, behavior, and next-risk areas.
- [AGENTS.md](AGENTS.md) gives future AI agents repo-specific working rules.

