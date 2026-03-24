# AGENTS

## Scope

These instructions are for future AI agents working in this repository.

## Repo-Specific Rules

- Preserve a Cupertino-only UI. Do not switch screens or components to Material widgets unless the user explicitly asks for that change.
- Keep the repository lightweight. Do not commit generated platform directories unless the user explicitly changes that policy.
- When changing the APK workflow, keep `flutter analyze` before the release build.
- Treat GitHub Actions as the canonical build path because local Flutter tooling may be unavailable on weak machines.

## Code Expectations

- Prefer small, direct changes over introducing heavy architecture for a simple app.
- If you refactor, keep behavior unchanged and update `AI_HANDOFF.md` when architectural assumptions change.
- Keep persistence backward-compatible when possible because app state is stored locally as JSON.
- Add tests if you introduce non-trivial state logic.

## Working Notes

- Main app logic currently lives in `lib/main.dart`.
- CI lives in `.github/workflows/build-release-apk.yml`.
- If you cannot run Flutter locally, say so clearly and rely on CI validation instead of guessing.

