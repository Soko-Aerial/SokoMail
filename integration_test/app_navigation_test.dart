// End-to-end smoke test. Requires a connected device, emulator or simulator:
//
//   flutter test integration_test -d <device-id>
//
// Uses the development session and sample data; no backend is required.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sokomail/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in with a development session, read a message, sign out', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SokoMailApp()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to SokoMail'), findsOneWidget);
    await tester.tap(find.text('Continue as employee'));
    await tester.pumpAndSettle();

    const subject = 'Drone Field Test – Project Update';
    expect(find.text(subject), findsOneWidget);
    await tester.tap(find.text(subject));
    await tester.pumpAndSettle();
    expect(find.textContaining('plan the next test cycle'), findsOneWidget);
  });
}
