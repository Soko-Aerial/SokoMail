# SokoMail

Secure company email for **SokoAerial Robotics**, built with Flutter for
**Android, iOS and the web** from a single codebase.

> **Status: Phase 3 (upgraded UI as an interactive prototype).** The
> olive-green design runs on phones, tablets and desktop browsers with
> light, dark and system themes. Mail interactions (folders, reading,
> starring, deleting, search, compose, drafts) work against **local demo
> data** in debug builds. There is no backend yet: no real sign-in, and
> nothing is sent. See
> [what is real and what is a placeholder](docs/architecture/overview.md#what-is-real-and-what-is-a-placeholder-phase-3).

## Architecture at a glance

- Feature-first folders with presentation / domain / data layers
- Riverpod 3 for state management and dependency injection (MVVM view models)
- go_router for URLs, deep links, an auth guard and admin-only routes
- One iOS-inspired, olive-green design system on every platform
  ([design system](docs/architecture/design_system.md))
- Adaptive shell: drawer + bottom folder bar + Compose button (phones);
  deep-green collapsible sidebar and top bar around framed list and reading
  panes (tablets and desktop)
- Dio-based API client, ready for the future SokoMail Go API

**Logo and app icon:** both are placeholders. In the app, the wordmark is
typographic; add the official SokoAerial Robotics logo to `assets/images/`
and render it in `lib/shared/widgets/sokomail_logo.dart` (ADR-017). The
launcher icon and favicon are an envelope on green; see [App icons](#app-icons).

All mail traffic will go through the Go API; the app never holds IMAP/SMTP
credentials. Details: [docs/architecture/overview.md](docs/architecture/overview.md).

## Prerequisites

| Tool | Version used |
| --- | --- |
| Flutter | 3.44.8 (stable) |
| Dart | 3.12.2 |
| Android | Android SDK with platform 36+ and accepted licenses (`flutter doctor --android-licenses`) |
| iOS | macOS with Xcode (iOS 13.0+ deployment target) |
| Web | Chrome or Edge |

Run `flutter doctor` to check your setup.

## Getting started

```bash
flutter pub get
flutter run -d chrome          # web (or -d edge)
flutter run -d <android-id>    # Android device/emulator (see `flutter devices`)
flutter run -d <ios-id>        # iOS simulator/device (macOS only)
```

On the sign-in screen of a debug build, choose **Continue as employee** or
**Continue as administrator**. This starts a local *development session*: it
is not authenticated by any server, uses sample data (`example.com`
addresses), shows a warning banner, and is compiled out of release builds.
Changes you make (stars, deletions, drafts) last until the app restarts.
Your theme choice and sidebar state are saved on the device.

## Configuration

Non-secret settings are passed at build time with `--dart-define`:

| Define | Default | Purpose |
| --- | --- | --- |
| `APP_ENV` | `development` | `development`, `staging` or `production` |
| `API_BASE_URL` | *(empty)* | Base URL of the SokoMail Go API. Must be `https://` in release builds. Not used yet. |
| `APP_VERSION` | `1.0.0` | Version shown in Settings > About. |
| `USE_DEV_FIXTURES` | `true` | Enables the development session and sample data. Always off in release builds. |

```bash
flutter run -d chrome \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://api.example.com
```

> **Never put secrets in `--dart-define`.** Values are embedded in the app
> binary and can be extracted. Passwords, API keys, private keys and tokens
> must never be stored in source code, defines or committed files.

## Quality checks

```bash
dart format .
flutter analyze
flutter test                         # unit + widget tests, no backend needed
flutter test integration_test -d <device-id>   # on a device/emulator/simulator
```

Screenshots of the main screens (`docs/screenshots/`) are rendered from the
real widgets with sample data:

```bash
flutter test test/tool/app_screenshots_test.dart --dart-define=UPDATE_SCREENSHOTS=true
```

## Builds

```bash
flutter build web                    # output: build/web
flutter build apk --debug            # output: build/app/outputs/flutter-apk/
flutter build appbundle              # release (requires a signing config)
```

**Web hosting:** the app uses path URLs (`/mail/<id>/inbox`). Configure the
web server to serve `index.html` for unknown paths. If hosted under a
sub-path, build with `--base-href /sub-path/`.

### App icons

The Android, iOS and web icons (including the browser favicon) are
generated from two 1024 x 1024 PNGs in `assets/branding/` by
`flutter_launcher_icons` (settings in `flutter_launcher_icons.yaml`):

| File | Used for | Content |
| --- | --- | --- |
| `app_icon.png` | iOS, web, Android 7 | Full square with an opaque background |
| `app_icon_foreground.png` | Android 8+ adaptive and themed icons | The mark only, on transparency, inside the central two-thirds |

```bash
dart run flutter_launcher_icons
```

The current files are a **placeholder** envelope rendered by
`test/tool/app_icon_test.dart`. To use the official logo, replace both
files and run the command above (not the placeholder tool). Browsers cache
favicons: reload with Ctrl+F5 to see a new one.

**Android release signing:** `android/app/build.gradle.kts` still signs
release builds with the debug key (Flutter template default). Configure a
release keystore (kept out of Git) before distributing.

### iOS (macOS only)

iOS cannot be built on Windows. On a Mac with Xcode:

```bash
flutter pub get
flutter build ios --debug --no-codesign   # compile check
flutter run -d <simulator-id>
open ios/Runner.xcworkspace               # set signing team, then archive
flutter build ipa                         # release (needs signing)
```

The bundle identifier is `com.sokoaerial.sokomail`; the display name is
`SokoMail`. Swift Package Manager is enabled; the `shared_preferences` and
`file_selector` plugins resolve through it (no CocoaPods). Check on a
simulator: theme persistence across relaunch, the Files picker from
Compose > Attach, safe areas on notched devices, and the swipe-back gesture.

## Project structure

```text
lib/
├── main.dart, bootstrap.dart   Entry point and start-up
├── app/                        Router, theme, adaptive layout, app shell
├── core/                       Config, errors, network, storage, security
├── shared/                     Reusable widgets, value types, dev sample data
└── features/                   auth, mailboxes, inbox, message, compose,
                                drafts, search, notifications, settings, admin
```

Full explanation and dependency rules:
[docs/architecture/folder_structure.md](docs/architecture/folder_structure.md).

## Documentation

- [Overview](docs/architecture/overview.md): system context, layers, security, offline plan
- [Design system](docs/architecture/design_system.md): tokens, typography, components, themes
- [Folder structure](docs/architecture/folder_structure.md): where code goes
- [State management](docs/architecture/state_management.md): Riverpod and MVVM
- [Navigation](docs/architecture/navigation.md): routes, guards, deep links
- [Responsive design](docs/architecture/responsive_design.md): breakpoints and layouts
- [Decisions](docs/architecture/decisions.md): architecture decision records
- [Go API integration](docs/api/README.md): client assumptions and open questions
