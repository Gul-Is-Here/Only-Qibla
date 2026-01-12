## Quick orientation

This is a Flutter application scaffolded from the default template. Primary app code lives in `lib/` (entry: `lib/main.dart`). Platform-specific hosts are present under `android/`, `ios/`, `macos/`, `linux/`, `windows/` and `web/`.

Keep in mind: the repo currently contains the default counter example and minimal dependencies (see `pubspec.yaml`). Use this document to quickly become productive when modifying or extending the app.

## Big-picture architecture (what to look at)
- `lib/` — main Dart code and the single app entry. For feature work, place Flutter/Dart code here and tests under `test/`.
- `android/app/src/{main,debug,profile}` — Android flavors/resources. Android build uses Kotlin-DSL Gradle files (`android/build.gradle.kts`, `android/app/build.gradle.kts`). Use the Gradle wrapper (`./gradlew`) when running platform builds.
- `ios/Runner` — iOS host sources and Info.plist. Builds require Xcode/macOS tooling.
- `macos/Runner`, `linux/runner`, `windows/runner`, `web/` — platform hosts; follow Flutter platform docs when adding native plugins.
- `pubspec.yaml` — dependency and asset declarations. This repo has no third-party packages besides `cupertino_icons` and uses `flutter_lints` for analysis.

Why this layout: It's the standard Flutter multi-platform template — keep Flutter/Dart logic inside `lib/` and native integration code within the respective platform folder.

## Developer workflows (commands & examples)
- Install deps: `flutter pub get` (run from repo root)
- Run on device/emulator (dev): `flutter run` — use IDE hot reload or press `r` in the terminal to hot-reload, `R` for hot-restart.
- Build APK/AAB: `flutter build apk` or `flutter build appbundle` (Android)
- Build iOS (macOS required): `flutter build ios` or open `ios/Runner.xcworkspace` in Xcode for signing.
- Run tests: `flutter test` (unit/widget tests in `test/`, see `test/widget_test.dart`)
- Analyze/lint: `flutter analyze` (project uses `analysis_options.yaml` + `flutter_lints`)

Platform notes and examples
- Android CI/build: use the Gradle wrapper `android/gradlew` (or `./gradlew` from repo root) to ensure consistent Gradle versions.
- iOS/macOS: signing and simulator/device selection happen in Xcode — editing `ios/Runner/Info.plist` or the Xcode project file is required for entitlements.

## Project-specific patterns and conventions
- Keep Dart UI and business logic in `lib/`. Avoid scattering cross-cutting logic into platform folders unless you need native APIs.
- Assets: there are no declared assets yet. To add images, update `flutter:` -> `assets:` in `pubspec.yaml`, then reference from Dart with `Image.asset('assets/...')`.
- Dependency changes: edit `pubspec.yaml` and run `flutter pub get`. Prefer adding pinned versions where appropriate.
- Lints: this project uses `flutter_lints` (see `analysis_options.yaml`). Follow the existing lint rules; modify only when necessary and document changes.

## Integration points & external dependencies
- Currently minimal: no network clients or platform plugins are present. When adding platform plugins, update `pubspec.yaml` and follow plugin docs for Android/iOS native setup (e.g., update `AndroidManifest.xml`, `Info.plist`, or platform Gradle files).
- If native code is added, remember to run platform-specific builds to catch integration issues early: `flutter build ios` (macOS/Xcode), `./gradlew assembleDebug` (android).

## Common tasks for an AI coding agent (examples)
- Add a new package: update `pubspec.yaml`, run `flutter pub get`, then implement usage in `lib/` and add a widget test in `test/`.
- Add an image asset: add file to `assets/`, declare it in `pubspec.yaml`, then use `Image.asset()` in `lib/` and add a small widget test that pumps the widget tree.
- Add platform permission (iOS): update `ios/Runner/Info.plist` with the permission key, then call the plugin from Dart.

## Files to inspect for context when editing
- `lib/main.dart` — app entry and example UI
- `pubspec.yaml` — dependencies, version, assets
- `analysis_options.yaml` — lint rules
- `test/widget_test.dart` — example test
- `android/app/src` and `ios/Runner` — platform integration points

## Safety and verification checklist for PRs
- Run `flutter analyze` and `flutter test` locally before pushing.
- Verify `flutter pub get` succeeds with no resolver issues after dependency changes.
- If native code or plugin changes are included, run at least one platform build (`flutter build apk` or `flutter build ios`) to surface integration errors.

If anything here is unclear or you want more detail about a specific area (CI, platform setup, or intended app behavior), tell me which section to expand and I'll iterate.
