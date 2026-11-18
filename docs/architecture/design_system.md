# Design system

SokoMail uses **one iOS-inspired design language on Android, iOS and the
web**: the same screens and components everywhere, adapted by available
width rather than by platform (see [responsive_design.md](responsive_design.md)).

All styling lives in `lib/app/theme/`. Screens read colours from the theme;
they never use colour constants directly.

## Colour tokens

Defined in `app_colors.dart` (`AppColors`), applied in `app_theme.dart`.

| Role | Light | Dark |
| --- | --- | --- |
| Primary olive | `#536537` | `#A4BA78` |
| Deep army green (headers, sidebar) | `#283423` | `#1C281C` |
| Header accent (Compose, selected counts on green) | `#A4BA78` | `#A4BA78` |
| Selected item on green | `#4A5A33` | `#3A4630` |
| Soft olive (pills, selection) | `#E4E9D5` | `#3A4630` |
| Background | `#F7F6F1` | `#151C16` |
| Surface (cards, panes) | `#FFFFFF` | `#242D24` |
| Secondary surface | `#F1F0E9` | `#2F392D` |
| Primary text | `#202820` | `#F0F3EB` |
| Secondary text | `#667063` | `#B5C0AD` |
| Muted gold (stars, avatars) | `#B5A269` | `#CDBB85` |
| Error | `#B3261E` | `#F2B8B5` |

Accessibility: every text/background pair used by the app meets WCAG AA
(4.5:1). `test/app/theme/app_theme_test.dart` checks this, including header
text, the sidebar Compose button and pills. Two supplied values were
adjusted to pass (see decisions.md, ADR-012).

### Where to read colours

| Need | Use |
| --- | --- |
| Standard roles | `Theme.of(context).colorScheme` (`primary`, `surface`, `onSurfaceVariant`, ...) |
| Brand surfaces: header, sidebar, soft olive, avatar palette | `context.brandColors` (`AppBrandColors`) |
| Success / warning | `context.statusColors` (`AppStatusColors`) |

## Typography

`app_typography.dart`: Material 3 sizes with iOS-style weights (bold large
titles, tighter headings, 1.45-1.5 body line height). The platform font is
used (San Francisco on iOS, Roboto elsewhere) until a brand typeface is
chosen; add it to `assets/fonts/` and set `fontFamily` there.

## Components

| Component | Where | Notes |
| --- | --- | --- |
| `SokoMailLogo` | `shared/widgets/` | Typographic placeholder; `onDark` for headers. Official logo goes here (ADR-017). |
| `BrandLandscape` | `shared/widgets/` | Decorative ridge lines and a small drone in flat greens, drawn in code. Only in branded areas: sign-in panel, sidebar and drawer footers (ADR-018). |
| `BrandAppBar` | `app/layout/` | Deep-green bar with centred wordmark (phone inbox). |
| `ResponsivePage`, `PageHeader` | `app/layout/` | Secondary-page chrome: green app bar on phones, a framed card with a title on wider layouts. |
| `PaneCard` | `app/layout/` | Rounded surface card for the list and reading panes on tablet and desktop (soft shadow in light mode, flat in dark). |
| `MessageListTile` | `shared/widgets/` | Unread dot, avatar, sender, time, subject, preview, attachment and star; selected rows get a soft-olive fill and an olive bar. |
| `SenderAvatar` | `shared/widgets/` | Initials with a deterministic colour per sender. |
| `PillLabel`, `CountBadge` | `shared/widgets/` | Folder names; counts in four tones (filled, muted, on green, selected on green). |
| `MenuItemLabel` | `shared/widgets/` | Icon + label for popup menu entries; wraps rather than overflowing. |
| `AppSearchField` | `shared/widgets/` | Rounded search; read-only mode opens the Search screen. |
| `AppButton`, `AppTextField` | `shared/widgets/` | Pill buttons and filled fields from the theme. |
| `AppEmptyState`, `AppErrorView`, `AppLoadingIndicator` | `shared/widgets/` | Consistent empty, error and loading states. |
| `PlaceholderTag`, `showPlaceholderNotice` | `shared/widgets/` | Mark and explain features that need the API. |
| `MessageBodyText` | `features/message/presentation/widgets/` | Plain-text body with paragraphs, olive bullet dots and bold list headings. No HTML is interpreted. |
| `AttachmentCard`, `FileTypeBadge` | `features/message/presentation/widgets/` | Rounded card with a coloured file-type badge (PDF, XLS, DOC, image), name, size and download. |
| Shell drawer, sidebar, bottom bar, top bar | `app/layout/shell/` | See responsive_design.md. |

## Motion and interaction

- Cupertino page transitions on every platform; the reading pane slides in on
  phones. The slide-in is skipped when the platform requests reduced motion
  (`MediaQuery.disableAnimations`).
- Bouncing scroll physics and no Material overscroll glow.
- Press feedback is a subtle highlight (no ink ripple).
- Touch targets are at least 44 px; icon buttons default to 44 x 44.

## Theme modes

Light, Dark and System Default, chosen in **Settings > Appearance** (radio
list and previews) or with the sun/moon toggle in the tablet and desktop top
bar. The choice is saved with `shared_preferences` and restored on the next
launch.

Dark mode is designed, not inverted: the green chrome deepens to `#1C281C`,
panes sit on `#242D24` without shadows, the olive brightens to `#A4BA78` for
contrast, and avatar colours switch to light tints with dark initials.

## App icon

The launcher icon, browser favicon and PWA icons are generated from
`assets/branding/` (see README, "App icons", and decisions.md, ADR-019).
The current artwork is a placeholder: an envelope in the header accent
`#A4BA78` on deep army green `#283423`, with the flap cut out so the same
shape works as Android's single-colour themed icon. Replace it with the
official logo when it is supplied; do not design a new logo.

## Screenshots

`docs/screenshots/` holds renders of the main screens (desktop light, dark
and collapsed; tablet two-pane; phone inbox, drawer, message, settings,
compose; both sign-in layouts). They are generated from the real widgets
with sample data:

```sh
flutter test test/tool/app_screenshots_test.dart --dart-define=UPDATE_SCREENSHOTS=true
```

The tool is skipped in normal test runs. It loads Roboto and Material Icons
from the Flutter SDK so text renders as on Android and the web.
