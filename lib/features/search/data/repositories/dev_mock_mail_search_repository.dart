// DEVELOPMENT ONLY: searches the local demo store. See dev_mail_store.dart.

import 'package:sokomail/features/search/domain/repositories/mail_search_repository.dart';
import 'package:sokomail/shared/dev/dev_mail_store.dart';
import 'package:sokomail/shared/models/message_summary.dart';

class DevMockMailSearchRepository implements MailSearchRepository {
  const DevMockMailSearchRepository(this._store);

  final DevMailStore _store;

  @override
  Future<List<MessageSummary>> search({
    required String mailboxId,
    required String query,
  }) async {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const [];

    final matches = _store.inMailbox(mailboxId).where((message) {
      final haystack = [
        message.from.label,
        message.from.address,
        ...message.to.map((a) => '${a.label} ${a.address}'),
        message.subject,
        message.body,
      ].join(' ').toLowerCase();
      return terms.every(haystack.contains);
    }).toList()..sort((a, b) => b.sentAt.compareTo(a.sentAt));

    return [for (final message in matches) message.toSummary()];
  }
}
