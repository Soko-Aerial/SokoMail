import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/features/compose/presentation/providers/compose_controller.dart';
import 'package:sokomail/shared/extensions/byte_size.dart';
import 'package:sokomail/shared/models/email_address.dart';
import 'package:sokomail/shared/widgets/app_error_view.dart';
import 'package:sokomail/shared/widgets/app_loading_indicator.dart';

/// Compose a new message, reply or forward.
///
/// Real in this build: the form, recipient validation, Cc/Bcc, sender
/// selection, choosing attachments and saving a draft to local demo data.
/// Not available: sending and uploading files (they need the SokoMail API);
/// the UI says so instead of pretending.
class ComposeScreen extends ConsumerWidget {
  const ComposeScreen({
    super.key,
    required this.request,
    required this.onClose,
  });

  final ComposeRequest request;
  final VoidCallback onClose;

  static String titleFor(ComposeMode mode) => switch (mode) {
    ComposeMode.newMessage => 'New Message',
    ComposeMode.reply || ComposeMode.replyAll => 'Reply',
    ComposeMode.forward => 'Forward',
    ComposeMode.editDraft => 'Edit Draft',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(composeControllerProvider(request));
    final title = titleFor(request.mode);

    return state.when(
      skipLoadingOnReload: true,
      loading: () => Scaffold(
        appBar: AppBar(
          leading: CloseButton(onPressed: onClose),
          title: Text(title),
        ),
        body: const AppLoadingIndicator(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: CloseButton(onPressed: onClose),
          title: Text(title),
        ),
        body: AppErrorView(title: 'Could not start this message', error: error),
      ),
      data: (initial) => _ComposeForm(
        request: request,
        initial: initial,
        title: title,
        onClose: onClose,
      ),
    );
  }
}

class _ComposeForm extends ConsumerStatefulWidget {
  const _ComposeForm({
    required this.request,
    required this.initial,
    required this.title,
    required this.onClose,
  });

  final ComposeRequest request;
  final ComposeState initial;
  final String title;
  final VoidCallback onClose;

  @override
  ConsumerState<_ComposeForm> createState() => _ComposeFormState();
}

class _ComposeFormState extends ConsumerState<_ComposeForm> {
  late final _to = TextEditingController(text: widget.initial.to);
  late final _cc = TextEditingController(text: widget.initial.cc);
  late final _bcc = TextEditingController(text: widget.initial.bcc);
  late final _subject = TextEditingController(text: widget.initial.subject);
  late final _body = TextEditingController(text: widget.initial.body);

  /// Set after a send attempt so a missing recipient is flagged inline.
  bool _sendAttempted = false;

  ComposeController get _controller =>
      ref.read(composeControllerProvider(widget.request).notifier);

  ComposeState get _state =>
      ref.read(composeControllerProvider(widget.request)).value ??
      widget.initial;

  @override
  void dispose() {
    for (final controller in [_to, _cc, _bcc, _subject, _body]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDraft() async {
    await _controller.saveDraft();
    if (mounted) {
      _showMessage('Draft saved to local demo data (not synced).');
    }
  }

  Future<void> _attach() async {
    try {
      final added = await _controller.pickAttachments();
      if (added > 0 && mounted) {
        _showMessage(
          added == 1 ? 'Attached 1 file.' : 'Attached $added files.',
        );
      }
    } on Object {
      if (mounted) _showMessage('Could not open the file picker.');
    }
  }

  Future<void> _send() async {
    final state = _state;
    if (!state.hasValidRecipients) {
      // Problems are shown inline under the recipient fields.
      setState(() => _sendAttempted = true);
      return;
    }
    final saveInstead = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_off_rounded),
        title: const Text('Sending is not available yet'),
        content: const Text(
          'SokoMail sends mail through its API, which is not connected in '
          'this build. Your message has not been sent.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save as draft'),
          ),
        ],
      ),
    );
    if (saveInstead ?? false) await _saveDraft();
  }

  Future<void> _close() async {
    if (!_state.hasUnsavedChanges || _state.isEmpty) {
      widget.onClose();
      return;
    }
    final choice = await showDialog<_CloseChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this message?'),
        content: const Text('Your changes have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_CloseChoice.keep),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_CloseChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_CloseChoice.save),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );
    switch (choice) {
      case _CloseChoice.save:
        await _saveDraft();
        widget.onClose();
      case _CloseChoice.discard:
        widget.onClose();
      case _CloseChoice.keep || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(composeControllerProvider(widget.request)).value ??
        widget.initial;
    final controller = _controller;
    final scheme = Theme.of(context).colorScheme;

    String? errorFor(String raw) {
      final invalid = ComposeState.parseAddresses(
        raw,
      ).where((address) => !EmailAddress.isValid(address));
      return invalid.isEmpty ? null : 'Check: ${invalid.join(', ')}';
    }

    return PopScope(
      canPop: !state.hasUnsavedChanges || state.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: CloseButton(onPressed: _close),
          title: Text(widget.title),
          actions: [
            IconButton(
              tooltip: 'Attach files',
              icon: const Icon(Icons.attach_file_rounded),
              onPressed: _attach,
            ),
            IconButton(
              tooltip: 'Send',
              icon: const Icon(Icons.send_rounded),
              onPressed: _send,
            ),
            const SizedBox(width: 4),
          ],
        ),
        // In the bottom slot, so snack bars float above it instead of
        // covering Send.
        bottomNavigationBar: _ActionsBar(
          onSaveDraft: _saveDraft,
          onSend: _send,
          savedAsDraft: state.draftId != null && !state.hasUnsavedChanges,
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            // A short, fixed form: build it eagerly so fields scrolled out of
            // view keep their state and focus.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const _DemoNotice(),
                  const SizedBox(height: 8),
                  _FieldRow(
                    label: 'From',
                    child: _FromSelector(
                      state: state,
                      onChanged: controller.setFrom,
                    ),
                  ),
                  const Divider(),
                  _FieldRow(
                    label: 'To',
                    error:
                        errorFor(state.to) ??
                        (_sendAttempted && !state.hasRecipients
                            ? 'Add at least one recipient.'
                            : null),
                    trailing: state.showCcBcc
                        ? null
                        : TextButton(
                            onPressed: controller.showCcBcc,
                            child: const Text('Cc/Bcc'),
                          ),
                    child: _BareField(
                      key: const ValueKey('compose-to'),
                      controller: _to,
                      hint: 'Add recipients',
                      email: true,
                      onChanged: controller.setTo,
                    ),
                  ),
                  if (state.showCcBcc) ...[
                    const Divider(),
                    _FieldRow(
                      label: 'Cc',
                      error: errorFor(state.cc),
                      child: _BareField(
                        key: const ValueKey('compose-cc'),
                        controller: _cc,
                        hint: 'Add Cc recipients',
                        email: true,
                        onChanged: controller.setCc,
                      ),
                    ),
                    const Divider(),
                    _FieldRow(
                      label: 'Bcc',
                      error: errorFor(state.bcc),
                      child: _BareField(
                        key: const ValueKey('compose-bcc'),
                        controller: _bcc,
                        hint: 'Add Bcc recipients',
                        email: true,
                        onChanged: controller.setBcc,
                      ),
                    ),
                  ],
                  const Divider(),
                  _FieldRow(
                    label: 'Subject',
                    child: _BareField(
                      key: const ValueKey('compose-subject'),
                      controller: _subject,
                      hint: 'Subject',
                      onChanged: controller.setSubject,
                    ),
                  ),
                  const Divider(),
                  _BareField(
                    key: const ValueKey('compose-body'),
                    controller: _body,
                    hint: 'Write your message',
                    minLines: 10,
                    onChanged: controller.setBody,
                  ),
                  if (state.attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final attachment in state.attachments)
                          InputChip(
                            avatar: const Icon(
                              Icons.insert_drive_file_outlined,
                              size: 18,
                            ),
                            label: Text(
                              '${attachment.fileName} '
                              '(${attachment.sizeBytes.toFileSizeLabel()})',
                            ),
                            deleteButtonTooltipMessage:
                                'Remove ${attachment.fileName}',
                            onDeleted: () =>
                                controller.removeAttachment(attachment),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Attachments are not uploaded in this build.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CloseChoice { keep, discard, save }

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Demo build: messages cannot be sent yet. Drafts are saved '
                'to local demo data on this device only.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.child,
    this.trailing,
    this.error,
  });

  final String label;
  final Widget child;
  final Widget? trailing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailing = this.trailing;
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: child),
            ?trailing,
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 68, bottom: 8),
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _BareField extends StatelessWidget {
  const _BareField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.email = false,
    this.minLines,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool email;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final multiline = minLines != null;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: email
          ? TextInputType.emailAddress
          : (multiline ? TextInputType.multiline : TextInputType.text),
      textInputAction: multiline ? null : TextInputAction.next,
      autocorrect: !email,
      minLines: minLines,
      maxLines: multiline ? null : 1,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        filled: false,
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _FromSelector extends StatelessWidget {
  const _FromSelector({required this.state, required this.onChanged});

  final ComposeState state;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final mailboxes = state.senderMailboxes;
    if (mailboxes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text('No mailbox with permission to send'),
      );
    }
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: state.fromMailboxId,
        isExpanded: true,
        borderRadius: BorderRadius.circular(14),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        items: [
          for (final mailbox in mailboxes)
            DropdownMenuItem(
              value: mailbox.id,
              child: Text(
                mailbox.emailAddress,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom actions. Attaching lives in the app bar so both buttons keep
/// their full labels on narrow phones.
class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.onSaveDraft,
    required this.onSend,
    required this.savedAsDraft,
  });

  final VoidCallback onSaveDraft;
  final VoidCallback onSend;
  final bool savedAsDraft;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: OutlinedButton(
                        onPressed: onSaveDraft,
                        child: Text(
                          savedAsDraft ? 'Saved' : 'Save draft',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: onSend,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
