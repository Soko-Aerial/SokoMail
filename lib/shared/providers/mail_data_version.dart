import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A cross-feature signal meaning "mail data changed; reload what you show".
///
/// Providers that display mail (folder lists, counts, the reading pane,
/// search results) `ref.watch` it. View models call [MailDataVersion.bump]
/// after a successful change (star, read state, move, draft saved).
/// Later, server push events will bump it too.
///
/// Keeping this in `shared/` lets features stay independent: the inbox does
/// not need to know which screens display messages, and vice versa.
final mailDataVersionProvider = NotifierProvider<MailDataVersion, int>(
  MailDataVersion.new,
);

class MailDataVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
