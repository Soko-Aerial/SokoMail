import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/features/message/data/repositories/message_repository_provider.dart';
import 'package:sokomail/features/message/domain/entities/email_message.dart';
import 'package:sokomail/shared/models/mail_folder.dart';
import 'package:sokomail/shared/providers/mail_data_version.dart';

typedef MessageRef = ({String mailboxId, String messageId});

/// View model for the reading pane.
///
/// Auto-disposed when the pane closes, so message content is not kept in
/// memory longer than it is displayed. Opening an unread message marks it
/// as read once.
final messageDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MessageDetailController, EmailMessage, MessageRef>(
      MessageDetailController.new,
    );

class MessageDetailController extends AsyncNotifier<EmailMessage> {
  MessageDetailController(this.messageRef);

  final MessageRef messageRef;

  /// Read state is only changed automatically on the first load, so a later
  /// "Mark as unread" is not immediately undone by the reload it triggers.
  bool _hasLoaded = false;

  @override
  Future<EmailMessage> build() async {
    ref.watch(mailDataVersionProvider);
    final repository = ref.watch(messageRepositoryProvider);
    final message = await repository.getMessage(
      mailboxId: messageRef.mailboxId,
      messageId: messageRef.messageId,
    );

    final firstLoad = !_hasLoaded;
    _hasLoaded = true;
    if (firstLoad && !message.isRead) {
      await repository.setRead(
        mailboxId: messageRef.mailboxId,
        messageId: messageRef.messageId,
        read: true,
      );
      _notifyChanged();
      return message.copyWith(isRead: true);
    }
    return message;
  }

  Future<void> toggleStar() async {
    final message = state.value;
    if (message == null) return;
    await ref
        .read(messageRepositoryProvider)
        .setStarred(
          mailboxId: messageRef.mailboxId,
          messageId: messageRef.messageId,
          starred: !message.isStarred,
        );
    _notifyChanged();
  }

  Future<void> markUnread() async {
    await ref
        .read(messageRepositoryProvider)
        .setRead(
          mailboxId: messageRef.mailboxId,
          messageId: messageRef.messageId,
          read: false,
        );
    _notifyChanged();
  }

  /// Moves the message (Trash for delete, Spam, back to Inbox).
  Future<void> moveTo(MailFolder folder) async {
    await ref
        .read(messageRepositoryProvider)
        .moveToFolder(
          mailboxId: messageRef.mailboxId,
          messageId: messageRef.messageId,
          folder: folder,
        );
    _notifyChanged();
  }

  void _notifyChanged() => ref.read(mailDataVersionProvider.notifier).bump();
}
