# Architecture decision records

Short records of significant decisions. Add a new entry rather than editing
an accepted one; mark superseded entries as such.

---

## ADR-001: Feature-first structure with clean-architecture layers

**Status:** Accepted (Phase 1)

**Context.** SokoMail will grow to a dozen business areas (mailboxes, inbox,
compose, search, notifications, admin...) maintained by a small team.

**Decision.** Group code by feature under `lib/features/`, with
`presentation` / `domain` / `data` layers inside each feature, created only
when needed. Cross-cutting infrastructure lives in `core/`, reusable UI and
value types in `shared/`, composition (router, shell, theme) in `app/`.

**Consequences.** Features can be worked on independently; layering keeps the
domain testable without Flutter. Some features are thin in Phase 1 (search,
admin), which is acceptable: layers are added when a feature gets real logic.

## ADR-002: Riverpod for state management and dependency injection

**Status:** Accepted (Phase 1)

**Decision.** `flutter_riverpod` 3.x is the only state-management and DI
mechanism. Providers are hand-written (no `riverpod_generator`) to avoid
build_runner in Phase 1.

**Why.** Compile-safe dependency graph, first-class `AsyncValue` for loading
and error states, overrides for tests without a service locator, and
automatic disposal for screen-scoped state.

**Consequences.** No Provider, Bloc, GetX or get_it. Code generation may be
adopted later if provider boilerplate grows; it does not change the
architecture.

## ADR-003: go_router for navigation

**Status:** Accepted (Phase 1)

**Decision.** `go_router` 18.x with a single router, a `ShellRoute` for the
navigation chrome, a pure redirect guard, and route `metadata` for access
levels.

**Why.** Official Flutter package; URL-based routing gives deep links,
browser history and shareable message links on all platforms.

## ADR-004: Import Material from `material_ui`

**Status:** Accepted (Phase 1)

**Context.** From Flutter 3.44, Material is published as the `material_ui`
package; `package:flutter/material.dart` remains as a legacy in-framework
copy. go_router 18 and Riverpod 3.5 already depend on `material_ui`. Mixing
both libraries creates two different `Theme`/`ThemeData` types, so widgets
from one would not see the theme of the other.

**Decision.** All app code imports `package:material_ui/material_ui.dart`.

**Consequences.** One Material type system across the app and its
dependencies. Caveat for tests: `flutter_test`'s `find.byTooltip` matches the
legacy `Tooltip` only; use text, icon, type or key finders instead. If a
future third-party package still uses the legacy library, wrap it in
`MaterialUiCompatibilityBridge` (see the `material_ui` README).

## ADR-005: Dio behind `ApiClient` for HTTP

**Status:** Accepted (Phase 1)

**Decision.** `dio` 5.x, created by `createDio` and wrapped in `ApiClient`,
which exposes typed `get/post/put/delete` methods with explicit decoders and
converts every error into an `AppFailure`.

**Why.** Interceptors (auth, logging), cancellation, timeouts and a
replaceable transport (`HttpClientAdapter`) for testing without a network.

**Consequences.** Only remote data sources use `ApiClient`; widgets never see
Dio. Web cookie authentication will need `withCredentials` on Dio's browser
adapter when the auth milestone lands.

## ADR-006: Typed failures and a selective retry policy

**Status:** Accepted (Phase 1)

**Decision.** A sealed `AppFailure` hierarchy with a user-safe `userMessage`
and a never-displayed `debugMessage`. HTTP statuses map to failures in one
place (`mapStatusCode`). Riverpod's automatic retry is limited to transient
failures by `providerRetryPolicy`.

**Why.** Screens can switch exhaustively on failures; raw exception text
(which may contain server or request details) never reaches the UI or logs.

## ADR-007: Development session and sample data, compiled out of release

**Status:** Accepted (Phase 1, temporary)

**Context.** Navigation and layouts must be exercised before the Go API
exists, but a fake login must not be mistaken for authentication.

**Decision.** In debug/profile builds the login screen offers a clearly
labelled development session; mailbox and message repositories return
invented `example.com` sample data from `DevMock*` classes. All of it is
gated by `AppConfig.developmentToolsCompiledIn` (`!kReleaseMode`, a
compile-time constant) and `USE_DEV_FIXTURES`. A warning banner is always
visible during a development session. Without fixtures, repositories throw
`FeatureUnavailableFailure` rather than inventing data.

**Consequences.** Release builds contain neither the bypass nor the sample
data, and cannot sign in until the auth milestone. Remove this ADR's code
paths once a staging API is available for local development.

## ADR-008: Messages use `go`; compose uses `push`

**Status:** Accepted (Phase 1)

**Decision.** Opening a message uses `go` so the URL is shareable and
reflected in the browser. A `PopScope` in `MailWorkspace` makes system back
and `Escape` return to the folder. Compose is pushed above the shell because
it is a transient task.

**Consequences.** On the web, the address bar does not change while compose
is open (go_router does not reflect `push` in the URL by default). Deep
links to `/compose` still work.

## ADR-009: Path URL strategy on the web

**Status:** Accepted (Phase 1)

**Decision.** `usePathUrlStrategy()` for URLs without `#`.

**Consequences.** Hosting must rewrite unknown paths to `index.html`. Adds
the `flutter_web_plugins` SDK package (no third-party code).

## ADR-010: Defer Drift, secure storage, Firebase and code generation

**Status:** Accepted (Phase 1). Preferences persistence superseded by
ADR-013; attachments picker added by ADR-014. Drift, secure storage,
Firebase and code generation remain deferred.

**Decision.** Do not add packages before there is a concrete use case.
Phase 1 defines boundaries instead: `PreferencesStore` (in memory),
`AccessTokenSource` (returns null), `SyncStatus`, and the notifications
README.

**Consequences.** Smaller dependency surface and attack surface. Each later
milestone adds its package together with the code and tests that use it, and
records the choice here.

## ADR-011: Breakpoints from available width

**Status:** Accepted (Phase 1, provisional values)

**Decision.** Window size classes at 600 and 1024 px; list/detail panes
decided by the space the workspace actually receives (two panes from 640 px).

**Consequences.** Values may be tuned in the design-system milestone without
changing the structure. Phase 2 kept the breakpoints and widened the list
pane range to 300-440 px; Phase 3 set it to 36% of the width, clamped to
320-460 px.

---

## ADR-012: One iOS-inspired design system on every platform

**Status:** Accepted (Phase 2)

**Context.** The approved design (olive-green, rounded, iOS-like) must look
the same on Android, iOS and the web.

**Decision.** A single Material 3 `ThemeData` styled to the approved tokens,
not separate Material and Cupertino screens:

- Cupertino page transitions on every platform (`CupertinoPageTransitionsBuilder`
  from `cupertino_ui`, now a direct dependency).
- Bouncing scroll physics everywhere (`AppScrollBehavior`).
- Highlight-only press feedback (`NoSplash`), pill buttons, 14-20 px radii,
  flat surfaces (`surfaceTint` transparent), deep-green app bars.
- Brand surfaces Material has no slot for live in the `AppBrandColors` theme
  extension.

**Accessibility adjustments to the supplied tokens.** Two colours were
adjusted to reach WCAG AA (4.5:1) for text, and tests enforce the contrast:
error text uses `#B3261E` (instead of `#DC2626`), and the Compose button on
the sidebar uses `#5E7139` (a lighter olive measured about 3.8:1 with white
text). Phase 3 replaced that button with the light olive `#A4BA78` and
deep-green text, which passes AA in both themes (ADR-018).

## ADR-013: shared_preferences for persistent preferences

**Status:** Accepted (Phase 2). Supersedes the "in memory" part of ADR-010.

**Decision.** `SharedPreferencesStore` implements the existing
`PreferencesStore` boundary with `SharedPreferencesWithCache` (synchronous
reads after one async load in `bootstrap`). Only allow-listed keys
(`PreferenceKeys.all`) are stored. If platform storage fails, the app falls
back to memory and still starts.

**Consequences.** Theme and sidebar state survive restarts on Android
(SharedPreferences), iOS (NSUserDefaults) and the web (`localStorage`). The
store is for non-sensitive preferences only. `shared_preferences_android`
builds a small native (JNI) component.

## ADR-014: file_selector for attachments

**Status:** Accepted (Phase 2)

**Decision.** The Flutter team's `file_selector` package picks files on
Android, iOS and the web, behind an `AttachmentPicker` interface so tests use
a fake. Only metadata (name, type, size) is kept.

**Consequences.** No upload happens; the UI states this. Upload will be
implemented with the API milestone.

## ADR-015: Local demo store and the mail-data version signal

**Status:** Accepted (Phase 2, development only)

**Decision.** All `DevMock*` repositories share one in-memory `DevMailStore`
(`shared/dev/`), so starring, read state, moving messages and saving drafts
stay consistent across screens. Mutating view models call
`mailDataVersionProvider.bump()`; every provider that shows mail watches it
and reloads (`skipLoadingOnReload` keeps the old data visible meanwhile).

**Consequences.** Features stay decoupled: the inbox does not know which
other screens display messages. The same signal will be bumped by server
push events later. The store is compiled out of release builds with the
rest of the development fixtures (ADR-007).

## ADR-016: Features may use another feature's repository provider

**Status:** Accepted (Phase 2). Refines the dependency rules.

**Context.** Starring from the inbox list and pre-filling a reply in Compose
need the message feature's data, and Compose needs mailboxes and drafts.

**Decision.** A feature may use another feature's **domain types** and its
**repository provider** (`*_repository_provider.dart`, the feature's public
data API). It must not use another feature's data sources, mock classes,
screens, widgets or view models. Cross-feature UI is composed in `app/`.

## ADR-017: Typographic logo placeholder

**Status:** Accepted (Phase 2, temporary)

**Decision.** No official SokoAerial Robotics logo is in the project, and the
mark in the design reference is not reproduced. `SokoMailLogo`
(`lib/shared/widgets/sokomail_logo.dart`) renders a "Soko**Mail**" wordmark.

**Consequences.** When the official artwork is supplied, add it to
`assets/images/`, declare the folder in `pubspec.yaml` and render it inside
`SokoMailLogo`; every screen picks it up.

## ADR-018: Phase 3 shell: green frame, framed panes, sidebar on tablets

**Status:** Accepted (Phase 3)

**Context.** The approved Phase 3 designs show a deep-green application frame
on tablet and desktop (sidebar plus top bar) with the mail list and reader as
rounded cards, a collapsible sidebar on tablets, and decorative drone
landscapes in branded areas only.

**Decision.**

- Tablet and desktop share one shell: a deep-green sidebar and top bar
  around a light content sheet with a rounded top-left corner. The list and
  reader sit in `PaneCard`s. Tablets start with the sidebar collapsed to an
  icon rail and expand it with the top-bar toggle for the session; on
  desktop the collapsed state is saved (`sidebarCollapsedProvider`). The
  tablet drawer and tablet `BrandAppBar` were removed.
- The sidebar lists every mailbox the user can read with its unread count,
  replacing the separate mailbox selector widget (deleted as unused).
- Compose on green uses the light olive accent `#A4BA78` with deep-green
  text; counts on green use the same accent when selected.
- `BrandLandscape` draws ridge lines and a small drone in flat greens. It is
  code, not an image, and appears only on the sign-in panel and the sidebar
  and drawer footers, never behind mail content. It is decoration, not a
  logo.
- Toolbars and rows degrade instead of overflowing (see
  responsive_design.md, "Reading pane toolbar").

**Consequences.** Tablets gain the desktop layout at the cost of 84 px for
the rail. The tagline "Aerial robotics for a safer, more connected world"
in the drawer footer was taken from the design reference and needs
confirmation from SokoAerial Robotics before release.

## ADR-019: Generated app icons, placeholder artwork until the official logo

**Status:** Accepted (Phase 3, placeholder artwork)

**Context.** Android, iOS and the web (launcher icons, browser favicon, PWA
icons) still showed Flutter's default logo. No official SokoAerial Robotics
logo is in the project, and the mark in the design references must not be
reproduced (ADR-017).

**Decision.**

- `flutter_launcher_icons` (dev dependency, build time only) generates every
  platform icon from two 1024 x 1024 PNGs in `assets/branding/`, configured
  in `flutter_launcher_icons.yaml`: Android legacy, adaptive and themed
  (monochrome) icons; the iOS app icon set without alpha; the web favicon,
  PWA icons (including maskable) and manifest colours.
- Until the official artwork is supplied, the source PNGs are a
  placeholder: a plain envelope in the header accent `#A4BA78` on deep army
  green `#283423`, drawn in code by `test/tool/app_icon_test.dart`. It is a
  generic mail symbol, not a company logo.
- The browser `theme-color` (index.html and manifest) changes from the
  Phase 1 navy `#17365D` to deep army green.

**Consequences.** Switching to the official logo is one step: replace both
PNGs (same names) and run `dart run flutter_launcher_icons`. The generator
also writes legacy iOS sizes (50, 57 and 72 pt) that iOS 13 and later
ignore. The in-app wordmark (`SokoMailLogo`) is unchanged. The iOS icon set
was generated on Windows and has not been checked in Xcode yet.
