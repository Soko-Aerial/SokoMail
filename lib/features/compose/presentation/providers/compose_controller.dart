import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/features/compose/data/datasources/attachment_picker.dart';
import 'package:sokomail/features/drafts/data/repositories/draft_repository_provider.dart';
import 'package:sokomail/features/drafts/domain/entities/email_draft.dart';
import 'package:sokomail/features/mailboxes/data/repositories/mailbox_repository_provider.dart';
import 'package:sokomail/features/mailboxes/domain/entities/mailbox.dart';
import 'package:sokomail/features/message/data/repositories/message_repository_provider.dart';
import 'package:sokomail/features/message/domain/entities/email_message.dart';
import 'package:sokomail/shared/models/attachment.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/providers/mail_data_version.dart';

enum ComposeMode {
  newMessage,
  reply,
  replyAll,
  forward,

  /// Continue editing a saved draft (opened from the Drafts folder).
  editDraft;

  static ComposeMode parse(String? raw) => values.firstWhere(
    (mode) => mode.name == raw,
    orElse: () => ComposeMode.newMessage,
  );
}

/// What to compose: a new message, or a reply/forward of [messageId].
typedef ComposeRequest = ({
  ComposeMode mode,
  String? mailboxId,
  String? messageId,
});

/// Immutable state of the compose form.
@immutable
class ComposeState {
  const ComposeState({
    this.fromMailboxId,
    this.senderMailboxes = const [],
    this.to = '',
    this.cc = '',
    this.bcc = '',
    this.subject = '',
    this.body = '',
    this.attachments = const [],
    this.showCcBcc = false,
    this.inReplyToMessageId,
    this.draftId,
    this.hasUnsavedChanges = false,
  });

  /// Mailbox the message would be sent from.
  final String? fromMailboxId;

  /// Mailboxes the user may send from.
  final List<Mailbox> senderMailboxes;

  /// Raw recipient input, separated by commas, semicolons or spaces.
  final String to;
  final String cc;
  final String bcc;
  final String subject;
  final String body;
  final List<Attachment> attachments;
  final bool showCcBcc;
  final String? inReplyToMessageId;

  /// Set once the message has been saved as a (local demo) draft.
  final String? draftId;
  final bool hasUnsavedChanges;

  static final _separators = RegExp(r'[,;\s]+');

  static List<String> parseAddresses(String raw) => raw
      .split(_separators)
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  List<String> get allRecipients => [
    ...parseAddresses(to),
    ...parseAddresses(cc),
    ...parseAddresses(bcc),
  ];

  List<String> get invalidRecipients => allRecipients
      .where((address) => !EmailAddress.isValid(address))
      .toList(growable: false);

  bool get hasRecipients => allRecipients.isNotEmpty;

  bool get hasValidRecipients => hasRecipients && invalidRecipients.isEmpty;

  bool get isEmpty =>
      allRecipients.isEmpty &&
      subject.trim().isEmpty &&
      body.trim().isEmpty &&
      attachments.isEmpty;

  ComposeState copyWith({
    String? fromMailboxId,
    List<Mailbox>? senderMailboxes,
    String? to,
    String? cc,
    String? bcc,
    String? subject,
    String? body,
    List<Attachment>? attachments,
    bool? showCcBcc,
    String? draftId,
    bool? hasUnsavedChanges,
  }) {
    return ComposeState(
      fromMailboxId: fromMailboxId ?? this.fromMailboxId,
      senderMailboxes: senderMailboxes ?? this.senderMailboxes,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      attachments: attachments ?? this.attachments,
      showCcBcc: showCcBcc ?? this.showCcBcc,
      inReplyToMessageId: inReplyToMessageId,
      draftId: draftId ?? this.draftId,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

/// View model for the compose screen.
///
/// Auto-disposed: the message is discarded when the screen closes unless it
/// was saved as a draft. Sending requires the SokoMail API, which is not
/// connected, so [isSendingAvailable] is false.
final composeControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ComposeController, ComposeState, ComposeRequest>(
      ComposeController.new,
    );

class ComposeController extends AsyncNotifier<ComposeState> {
  ComposeController(this.request);

  final ComposeRequest request;

  static const isSendingAvailable = false;

  @override
  Future<ComposeState> build() async {
    final mailboxes = await ref
        .read(mailboxRepositoryProvider)
        .getAccessibleMailboxes();
    final senders = mailboxes.where((m) => m.canSend).toList();
    final requested = senders.where((m) => m.id == request.mailboxId);
    final from = requested.firstOrNull ?? senders.firstOrNull;
    final base = ComposeState(
      fromMailboxId: from?.id,
      senderMailboxes: senders,
    );

    final mailboxId = request.mailboxId;
    final messageId = request.messageId;
    if (request.mode == ComposeMode.newMessage ||
        mailboxId == null ||
        messageId == null) {
      return base;
    }

    final original = await ref
        .read(messageRepositoryProvider)
        .getMessage(mailboxId: mailboxId, messageId: messageId);
    // Only the mailbox being replied from is "me": other team mailboxes the
    // employee can read are still legitimate Reply All recipients.
    final ownAddresses = {
      for (final m in mailboxes)
        if (m.id == mailboxId || m.id == from?.id) m.emailAddress.toLowerCase(),
    };
    return ComposeTemplates.prefill(
      base,
      mode: request.mode,
      original: original,
      ownAddresses: ownAddresses,
    );
  }

  ComposeState get _current => state.value ?? const ComposeState();

  void _edit(ComposeState Function(ComposeState) change) {
    state = AsyncData(change(_current).copyWith(hasUnsavedChanges: true));
  }

  void setFrom(String mailboxId) =>
      _edit((s) => s.copyWith(fromMailboxId: mailboxId));

  void setTo(String value) => _edit((s) => s.copyWith(to: value));

  void setCc(String value) => _edit((s) => s.copyWith(cc: value));

  void setBcc(String value) => _edit((s) => s.copyWith(bcc: value));

  void setSubject(String value) => _edit((s) => s.copyWith(subject: value));

  void setBody(String value) => _edit((s) => s.copyWith(body: value));

  void showCcBcc() => state = AsyncData(_current.copyWith(showCcBcc: true));

  void removeAttachment(Attachment attachment) => _edit(
    (s) => s.copyWith(
      attachments: [
        for (final a in s.attachments)
          if (a.id != attachment.id) a,
      ],
    ),
  );

  /// Opens the file picker. Returns the number of files added.
  Future<int> pickAttachments() async {
    final picked = await ref.read(attachmentPickerProvider).pickFiles();
    if (picked.isEmpty) return 0;
    _edit((s) => s.copyWith(attachments: [...s.attachments, ...picked]));
    return picked.length;
  }

  bool get canSend => isSendingAvailable && _current.hasValidRecipients;

  /// Saves the message as a draft (local demo data in development builds).
  Future<void> saveDraft() async {
    final current = _current;
    List<EmailAddress> addresses(String raw) => [
      for (final value in ComposeState.parseAddresses(raw)) EmailAddress(value),
    ];

    final id = await ref
        .read(draftRepositoryProvider)
        .saveDraft(
          EmailDraft(
            id: current.draftId,
            mailboxId: current.fromMailboxId ?? request.mailboxId ?? '',
            to: addresses(current.to),
            cc: addresses(current.cc),
            bcc: addresses(current.bcc),
            subject: current.subject,
            bodyText: current.body,
            attachments: current.attachments,
            inReplyToMessageId: current.inReplyToMessageId,
            updatedAt: DateTime.now(),
          ),
        );
    ref.read(mailDataVersionProvider.notifier).bump();
    state = AsyncData(current.copyWith(draftId: id, hasUnsavedChanges: false));
  }
}

/// Builds reply and forward drafts from an original message.
abstract final class ComposeTemplates {
  static ComposeState prefill(
    ComposeState base, {
    required ComposeMode mode,
    required EmailMessage original,
    required Set<String> ownAddresses,
  }) {
    bool notOwn(EmailAddress a) =>
        !ownAddresses.contains(a.address.toLowerCase());
    String join(Iterable<EmailAddress> addresses) =>
        addresses.map((a) => a.address).toSet().join(', ');

    return switch (mode) {
      ComposeMode.newMessage => base,
      ComposeMode.reply => _withOriginal(
        base,
        original,
        to: join([original.from]),
        subject: _prefixed('Re:', original.subject),
        body: _quoted(original),
      ),
      ComposeMode.replyAll => _withOriginal(
        base,
        original,
        to: join([original.from, ...original.to].where(notOwn)),
        cc: join(original.cc.where(notOwn)),
        subject: _prefixed('Re:', original.subject),
        body: _quoted(original),
      ),
      ComposeMode.forward => _withOriginal(
        base,
        original,
        subject: _prefixed('Fwd:', original.subject),
        body: _forwarded(original),
        attachments: original.attachments,
      ),
      ComposeMode.editDraft => ComposeState(
        fromMailboxId: base.fromMailboxId,
        senderMailboxes: base.senderMailboxes,
        to: join(original.to),
        cc: join(original.cc),
        bcc: join(original.bcc),
        subject: original.subject,
        body: original.bodyText,
        attachments: original.attachments,
        showCcBcc: original.cc.isNotEmpty || original.bcc.isNotEmpty,
        draftId: original.id,
      ),
    };
  }

  static ComposeState _withOriginal(
    ComposeState base,
    EmailMessage original, {
    String to = '',
    String cc = '',
    required String subject,
    required String body,
    List<Attachment> attachments = const [],
  }) {
    return ComposeState(
      fromMailboxId: base.fromMailboxId,
      senderMailboxes: base.senderMailboxes,
      to: to,
      cc: cc,
      subject: subject,
      body: body,
      attachments: attachments,
      showCcBcc: cc.isNotEmpty,
      inReplyToMessageId: original.id,
    );
  }

  static String _prefixed(String prefix, String subject) =>
      subject.toLowerCase().startsWith(prefix.toLowerCase())
      ? subject
      : '$prefix $subject';

  static String _timestamp(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _quoted(EmailMessage original) {
    final quoted = original.bodyText
        .split('\n')
        .map((line) => '> $line')
        .join('\n');
    return '\n\nOn ${_timestamp(original.sentAt)}, '
        '${original.from.label} <${original.from.address}> wrote:\n$quoted';
  }

  static String _forwarded(EmailMessage original) {
    final to = original.to.map((a) => a.address).join(', ');
    return '\n\n---------- Forwarded message ----------\n'
        'From: ${original.from.label} <${original.from.address}>\n'
        'Date: ${_timestamp(original.sentAt)}\n'
        'Subject: ${original.subject}\n'
        'To: $to\n\n'
        '${original.bodyText}';
  }
}
