# AI Handoff

## Project Summary

This repository contains a Flutter Pomodoro app with a deliberately Cupertino-only interface. The app uses a small multi-file structure with a controller, models, a SQLite-backed storage service, and tab-specific UI files. State now persists locally with `sqflite`.

The repo does not check in generated platform folders. GitHub Actions recreates the Android host project before analysis and release APK build.

## Current Behavior

- Timer modes: focus, short break, long break
- Running timer survives tab changes, app backgrounding, and app removal from recents by persisting wall-clock end time
- Project selection with per-project colors
- Project creation, editing, and deletion
- Each project now opens its own detail page with project totals and a dedicated task-manager-style task list
- Tasks can be created inside each project
- Focus sessions can be associated with the currently selected task or logged without a task
- Task selection from the focus screen now routes through the selected project's detail page instead of a flat action sheet
- While a timer is running, timer mode, project, task, and active-mode minute changes are intentionally locked
- Confirmation dialogs for timer reset and project deletion
- Adjustable timer durations from the focus screen and from settings
- Session completion tracking
- Daily, weekly, and monthly chart views in stats
- Daily stats use a project pie chart, and weekly/monthly stats use `fl_chart` bar charts
- Seven-day chart and top-project ranking
- Top-task statistics
- Settings tab with import/export of a full JSON snapshot
- Local persistence is relational in SQLite tables for projects, tasks, sessions, settings, and timer state
- Import/export still uses a JSON snapshot format for backup and restore

## Repository Layout

- `lib/main.dart`: entrypoint and `PomodoroApp` export
- `lib/app/app.dart`: top-level Cupertino app
- `lib/controllers/pomodoro_controller.dart`: timer logic, state mutations, persistence coordination, and statistics helpers
- `lib/models/`: app, timer, project, task, and persistence models
- `lib/services/app_storage.dart`: SQLite storage adapter and JSON import/export codec helpers
- `lib/screens/`: tab UI and main shell
- `lib/screens/project_detail_page.dart`: per-project page used for project management and focus-task selection
- `lib/screens/stats_tab.dart`: `fl_chart`-based daily/weekly/monthly chart UI
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
- Substantive code changes should be reflected in this file before commit.

## Known Technical Debt

- Test coverage is still minimal and currently limited to a basic widget smoke test.
- There is no notification/alarm behavior when a session completes.
- Import/export currently uses JSON text and clipboard flows, not file pickers.
- SQLite persistence currently rewrites small tables from the in-memory snapshot on save rather than doing targeted row-level mutations.
- The focus screen and settings screen both mutate the same duration defaults, which is intentional but should be kept consistent if the UX changes.

## Recommended Next Steps

1. Add tests around state transitions and statistics calculations.
2. Add local notifications so session completion is visible while the app is backgrounded.
3. Consider file-based import/export if text-based backup becomes too awkward.
4. Add more targeted widget tests for settings, import/export validation, task flows, and resume-after-close timer behavior.
