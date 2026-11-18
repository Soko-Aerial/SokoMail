# Responsive design

One set of screens serves phones, tablets and desktop browsers. Layout
decisions are based on **available width**, never on the operating system:
an iPad in split view and a narrow desktop browser window both get the
compact layout. The visual language is described in
[design_system.md](design_system.md).

## Breakpoints (provisional)

Defined in `lib/app/layout/app_breakpoints.dart`:

| Window size class | Width (logical px) | Typical devices |
| --- | --- | --- |
| `compact` | < 600 | Phones in portrait |
| `medium` | 600-1023 | Tablets, phones in landscape, narrow browser windows |
| `expanded` | >= 1024 | Desktop browsers, large tablets in landscape |

## The shell

`AdaptiveScaffold` (`app/layout/adaptive_scaffold.dart`) provides layout
slots; `AppShell` (`app/layout/app_shell.dart`) fills them with SokoMail's
navigation using the widgets in `app/layout/shell/`.

| | compact (phones) | medium (tablets) | expanded (desktop) |
| --- | --- | --- | --- |
| Top | Each page's deep-green app bar (inbox: menu, wordmark, search, more) | Deep-green top bar: sidebar toggle, mail search (Ctrl/Cmd+K), sun/moon theme toggle, notifications, help, account | Same top bar; the account shows name and company when there is room |
| Navigation | Slide-out drawer (wordmark, account, folders with counts, Mailboxes, Search, Settings, Help) + bottom folder bar (Inbox, Sent, Drafts, Spam, Trash) | Deep-green sidebar, collapsed to an 84 px icon rail by default; the toggle expands it to 272 px for the session | Deep-green sidebar (272 px): wordmark, Compose, folders with unread counts, Mailboxes section, Settings; collapses to the icon rail (saved) |
| Compose | Floating button on folder pages | Sidebar button (lime square when collapsed) | Sidebar button |
| Mail | One pane: list, then full-screen reader on a green header | Two framed panes from 640 px of content width, otherwise one | Three columns: sidebar, framed list, framed reader |

```text
compact (<600)       medium (600-1023)                  expanded (>=1024)
+--------------+     +--+---------------------------+   +--------+-----------------------------+
| = SokoMail Q:|     |[]| = [Search ...]  sun bell DE|   |SokoMail| = [Search ...] sun bell DE  |
|  ----------  |     |--|  +--------+ +-----------+ |   |Compose |  +--------+ +--------------+|
| Inbox (3) Y= |     |In|  | Inbox  | | <- Reply  | |   |Inbox 3 |  | Inbox  | | Reply  Reply ||
| [Search]     |     |St|  | msg    | | Subject   | |   |Starred |  | msg    | | Subject      ||
| message      |     |Se|  | msg    | | Sender    | |   |Sent    |  | msg    | | Body         ||
| message  (+) |     |Dr|  | msg    | | Body      | |   |Mailbox.|  | msg    | | [PDF] [XLS]  ||
|In Snt Dft Sp |     |  |  +--------+ +-----------+ |   |  ~^~   |  +--------+ +--------------+|
+--------------+     +--+---------------------------+   +--------+-----------------------------+
```

Compact pages put `AdaptiveScaffold.drawerButtonOf(context)` in their app
bar's `leading` slot; it returns the menu button only when needed.
Secondary pages use `ResponsivePage`: a green app bar with a back button on
phones, a framed card with a title on wider layouts.

The sidebar's decorative landscape fills whatever height the navigation
leaves; on short windows it scrolls below the last item instead of
squeezing the list.

## List and detail: `ListDetailLayout`

`lib/app/layout/responsive_layout.dart`. It measures the space it actually
receives, after the sidebar has taken its share:

- **>= 640 px:** two panes, each in a `PaneCard` with a 16 px gap on
  tablet and desktop. The list takes 36% of the width, clamped to 320-460
  px; the reading pane fills the rest.
- **< 640 px:** one pane. The list stays mounted offstage while a message is
  open (its scroll position survives) and the reader slides in from the
  right; the slide is skipped when the platform requests reduced motion.

### Reading pane toolbar

The toolbar (back; Reply / Reply all / Forward; Delete, Archive, Labels,
More) never wraps or overflows. It drops detail in steps as the pane narrows
or text gets larger: reply labels first (their width is measured with the
current font and text scale), then Archive and Labels move into More, then
the reply group is hidden (Reply, Reply all and Forward buttons always follow
the message). In narrow panes the sender's date moves under the recipients,
and "Download all" moves under the attachment count.

## Rules for screens

- Never use fixed screen dimensions. Constrain content with
  `ConstrainedBox(maxWidth: ...)` (forms 420 px, settings 680 px, reading and
  compose 860 px) and let it shrink.
- Content that may be taller than the screen scrolls.
- Text that can be long (subjects, names, addresses, labels in rows) uses
  `maxLines`/`ellipsis` or sits in a `Flexible`.
- Respect safe areas; full-screen pages wrap content in `SafeArea` where no
  app bar does it.
- Touch targets are at least 44 px.
- Keyboard and mouse: list rows, buttons and navigation are focusable with
  hover states; `Escape` closes an open message; Enter in the top search bar
  searches.

## Testing layouts

`test/app/layout/responsive_layout_test.dart` covers breakpoints, each
shell variant, sidebar collapse persistence, the tablet sidebar toggle, one
versus two panes, the reading pane at 1.5x text size, and every main page
(including Compose, Search, Mailboxes and Settings) at 320x568, 390x844,
844x390, 800x1024, 1000x800 and 1440x900 with no overflow errors. Use
`setViewport(tester, size)` from `test/helpers/test_app.dart`.

For visual review, `test/tool/app_screenshots_test.dart` renders the main
screens to `docs/screenshots/` (see design_system.md).
