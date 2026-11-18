import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/features/inbox/data/repositories/message_list_repository_provider.dart';
import 'package:sokomail/features/message/data/repositories/message_repository_provider.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/models/message_summary.dart';
import 'package:sokomail/shared/providers/mail_data_version.dart';

/// Identifies one folder of one mailbox.
typedef FolderRef = ({String mailboxId, MailFolder folder});

/// Messages in a folder, newest first. Reloads whenever mail data changes.
final folderMessagesProvider = FutureProvider.autoDispose
    .family<List<MessageSummary>, FolderRef>((ref, folder) {
      ref.watch(mailDataVersionProvider);
      return ref
          .watch(messageListRepositoryProvider)
          .getMessages(mailboxId: folder.mailboxId, folder: folder.folder);
    });

/// Navigation badge counts for a mailbox (see `getBadgeCounts`).
final folderBadgeCountsProvider = FutureProvider.autoDispose
    .family<Map<MailFolder, int>, String>((ref, mailboxId) {
      ref.watch(mailDataVersionProvider);
      return ref
          .watch(messageListRepositoryProvider)
          .getBadgeCounts(mailboxId: mailboxId);
    });

/// Local list filters (applied on the client to the loaded page).
enum MessageFilter {
  all('All messages'),
  unread('Unread'),
  starred('Starred'),
  attachments('With attachments');

  const MessageFilter(this.label);

  final String label;

  bool matches(MessageSummary message) => switch (this) {
    MessageFilter.all => true,
    MessageFilter.unread => !message.isRead,
    MessageFilter.starred => message.isStarred,
    MessageFilter.attachments => message.hasAttachments,
  };
}

/// Local sort orders.
enum MessageSort {
  newestFirst('Newest first'),
  oldestFirst('Oldest first'),
  unreadFirst('Unread first');

  const MessageSort(this.label);

  final String label;

  List<MessageSummary> apply(Iterable<MessageSummary> messages) {
    final sorted = messages.toList();
    switch (this) {
      case MessageSort.newestFirst:
        sorted.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      case MessageSort.oldestFirst:
        sorted.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      case MessageSort.unreadFirst:
        sorted.sort((a, b) {
          if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
          return b.sentAt.compareTo(a.sentAt);
        });
    }
    return sorted;
  }
}

/// What a folder screen shows: filter and sort order.
@immutable
class FolderViewState {
  const FolderViewState({
    this.filter = MessageFilter.all,
    this.sort = MessageSort.newestFirst,
  });

  final MessageFilter filter;
  final MessageSort sort;

  List<MessageSummary> visible(List<MessageSummary> messages) =>
      sort.apply(messages.where(filter.matches));

  FolderViewState copyWith({MessageFilter? filter, MessageSort? sort}) =>
      FolderViewState(filter: filter ?? this.filter, sort: sort ?? this.sort);
}

/// View model for a folder screen: filter, sort and row actions.
final folderViewControllerProvider = NotifierProvider.autoDispose
    .family<FolderViewController, FolderViewState, FolderRef>(
      FolderViewController.new,
    );

class FolderViewController extends Notifier<FolderViewState> {
  FolderViewController(this.folderRef);

  final FolderRef folderRef;

  @override
  FolderViewState build() => const FolderViewState();

  void setFilter(MessageFilter filter) =>
      state = state.copyWith(filter: filter);

  void setSort(MessageSort sort) => state = state.copyWith(sort: sort);

  Future<void> toggleStar(MessageSummary message) async {
    await ref
        .read(messageRepositoryProvider)
        .setStarred(
          mailboxId: message.mailboxId,
          messageId: message.id,
          starred: !message.isStarred,
        );
    ref.read(mailDataVersionProvider.notifier).bump();
  }

  /// Marks every unread message in [messages] as read. Returns how many
  /// changed.
  Future<int> markAllRead(List<MessageSummary> messages) async {
    final repository = ref.read(messageRepositoryProvider);
    final unread = messages.where((m) => !m.isRead).toList();
    for (final message in unread) {
      await repository.setRead(
        mailboxId: message.mailboxId,
        messageId: message.id,
        read: true,
      );
    }
    if (unread.isNotEmpty) ref.read(mailDataVersionProvider.notifier).bump();
    return unread.length;
  }
}
