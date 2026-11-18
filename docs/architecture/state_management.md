# State management (Riverpod 3)

SokoMail uses `flutter_riverpod` 3.x for state management **and** dependency
injection. Providers are written by hand (no code generation).

## Provider kinds and when to use them

| Need | Use | Examples |
| --- | --- | --- |
| Inject a dependency (repository, client, config) | `Provider` | `messageRepositoryProvider`, `apiClientProvider`, `appConfigProvider` |
| Load data for a screen | `FutureProvider.autoDispose(.family)` | `folderMessagesProvider`, `folderBadgeCountsProvider`, `searchResultsProvider`, `accessibleMailboxesProvider` |
| UI state with actions (view model) | `NotifierProvider` (+ `.family`) | `authControllerProvider`, `themeModeControllerProvider`, `sidebarCollapsedProvider`, `folderViewControllerProvider` (filter + star) |
| Async state with actions | `AsyncNotifierProvider.autoDispose.family` | `messageDetailControllerProvider` (read, star, move), `composeControllerProvider` (pre-fill, edit, attach, save draft) |

Family notifiers receive their argument through the constructor:

```dart
final messageDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MessageDetailController, EmailMessage, MessageRef>(
      MessageDetailController.new,
    );

class MessageDetailController extends AsyncNotifier<EmailMessage> {
  MessageDetailController(this.messageRef);
  final MessageRef messageRef;
  ...
}
```

Rules:

- **State is immutable.** Notifiers replace `state`; they never mutate it.
- **Screen-scoped state is `autoDispose`** (message content, compose input,
  folder filters). App-wide state (auth, theme, sidebar) is not.
- **Family arguments are records** (value equality), e.g.
  `({String mailboxId, MailFolder folder})`.
- **Widgets `watch`, callbacks `read`.**
- **No global mutable state.** Everything lives in the `ProviderScope`
  created in `bootstrap.dart`.

## MVVM in practice

Screens render state and forward events; view models own the logic and
call repositories:

| View | View model | Logic it owns |
| --- | --- | --- |
| `MailFolderScreen` | `FolderViewController` | Filter (all, unread, starred, attachments), star toggle |
| `MessageScreen` | `MessageDetailController` | Load, mark read once on open, star, mark unread, move to Trash/Spam/Inbox |
| `ComposeScreen` | `ComposeController` + `ComposeTemplates` | Reply/forward/draft pre-fill, recipient parsing and validation, sender choice, attachments, save draft |
| `SettingsScreen` | `ThemeModeController` | Theme mode, persisted |

Pure logic (`ComposeState`, `ComposeTemplates`, `RouteGuard`) is unit-tested
without widgets.

## Keeping screens in sync: the mail-data version

`mailDataVersionProvider` (`lib/shared/providers/`) is a counter meaning
"mail data changed". Every provider that shows mail `ref.watch`es it; every
view model that changes mail calls `bump()` after a successful change. Lists,
badges, the reading pane and search results therefore update together
without knowing about each other. Lists use `when(skipLoadingOnReload: true)`
so the previous data stays visible while reloading.

## Rendering asynchronous state

`AsyncValue` is sealed; render all three cases with `when` (loading,
error -> `AppErrorView`, data). `AppErrorView` converts any error with
`AppFailure.from`, which also unwraps Riverpod's `ProviderException`.

## Repositories and providers

Each feature binds its repository interface in
`data/repositories/<name>_repository_provider.dart`. Development builds bind
the `DevMock*` implementation backed by the shared `DevMailStore`; other
builds throw `FeatureUnavailableFailure` until the API implementation
exists. Other features may use this provider (it is the feature's public
data API, see decisions.md ADR-016).

## Automatic retry

`bootstrap.dart` installs `providerRetryPolicy`: only network, timeout and
server (5xx) failures are retried, up to 3 times.

## Overrides for tests

```dart
ProviderScope(
  overrides: [
    messageListRepositoryProvider.overrideWithValue(FakeRepository()),
    attachmentPickerProvider.overrideWithValue(FakeAttachmentPicker()),
  ],
  retry: (_, _) => null,
  child: const SokoMailApp(),
);
```

Use `ProviderContainer.test(overrides: [...])` for pure Dart tests and
`tester.container()` in widget tests. Persistence is tested against
`InMemorySharedPreferencesAsync` (see `test/app/theme/app_theme_test.dart`).
