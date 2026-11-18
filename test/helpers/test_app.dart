import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sokomail/app/app.dart';
import 'package:sokomail/app/router/app_router.dart';
import 'package:sokomail/features/auth/domain/entities/app_user.dart';
import 'package:sokomail/features/auth/presentation/providers/auth_controller.dart';

/// Representative viewport sizes (logical pixels).
abstract final class TestViewports {
  static const phone = Size(390, 844);
  static const smallPhone = Size(320, 568);
  static const phoneLandscape = Size(844, 390);
  static const tablet = Size(800, 1024);
  static const tabletLandscape = Size(1000, 800);
  static const desktop = Size(1440, 900);
}

/// Sample-data subjects used across tests.
abstract final class SampleSubjects {
  /// dev-msg-001: unread, two attachments, sent to the team mailboxes.
  static const fieldTest = 'Drone Field Test – Project Update';

  /// dev-msg-002: unread, not starred, no attachments.
  static const engineeringSync = 'Engineering Sync – This Friday';

  /// dev-msg-004: read and starred.
  static const supplierUpdate = 'Supplier Delivery Update';

  /// dev-msg-005: read, not starred.
  static const policyReminder = 'Policy Reminder: Data Handling';

  static const batteryQuote = 'Battery supplier quote received';
  static const sentReply = 'Re: Drone Field Test – Project Update';
  static const draft = 'Field test feedback';
  static const spam = 'You have been selected for a free drone';
  static const trash = 'Meeting room booking cancelled';

  /// First message in the shared Operations mailbox.
  static const shared = 'Site access request – Kajiado range';

  /// Text only in the full body of [fieldTest] (beyond the list preview).
  static const fieldTestBodyOnly = 'plan the next test cycle';
}

/// Sets the test window size for the rest of the test.
void setViewport(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps the full app (router, theme, providers) and returns its container.
///
/// Provider retries are disabled so failing providers do not leave pending
/// timers behind.
Future<ProviderContainer> pumpSokoMailApp(
  WidgetTester tester, {
  Size size = TestViewports.desktop,
  List<Override> overrides = const [],
  UserRole? signedInAs,
  String? location,
}) async {
  setViewport(tester, size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: const SokoMailApp(),
    ),
  );
  await tester.pumpAndSettle();

  final container = tester.container();
  if (signedInAs != null) {
    container
        .read(authControllerProvider.notifier)
        .startDevelopmentSession(signedInAs);
    await tester.pumpAndSettle();
  }
  if (location != null) {
    container.read(appRouterProvider).go(location);
    await tester.pumpAndSettle();
  }
  return container;
}

extension RouterTestX on ProviderContainer {
  GoRouter get router => read(appRouterProvider);

  /// The current URI. Unlike `GoRouter.state`, also works on error pages.
  Uri get currentUri => router.routerDelegate.currentConfiguration.uri;

  /// The current location, including query parameters.
  String get location => currentUri.toString();
}

/// Simulates the Android system back button.
Future<void> pressSystemBack(WidgetTester tester) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    const MethodCall('popRoute'),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
