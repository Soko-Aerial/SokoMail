import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/features/search/data/repositories/mail_search_repository_provider.dart';
import 'package:sokomail/shared/models/message_summary.dart';
import 'package:sokomail/shared/providers/mail_data_version.dart';

typedef SearchRef = ({String mailboxId, String query});

/// Results for a query. An empty query returns no results.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<MessageSummary>, SearchRef>((ref, search) async {
      ref.watch(mailDataVersionProvider);
      final query = search.query.trim();
      if (query.isEmpty) return const [];
      return ref
          .watch(mailSearchRepositoryProvider)
          .search(mailboxId: search.mailboxId, query: query);
    });
