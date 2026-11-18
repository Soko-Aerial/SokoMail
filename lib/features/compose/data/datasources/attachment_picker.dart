import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/shared/models/attachment.dart';

/// Lets the user choose files to attach.
///
/// Only file metadata (name, type, size) is kept. Uploading attachments is
/// part of the API milestone; nothing is uploaded in this build.
abstract interface class AttachmentPicker {
  /// Returns the chosen files, or an empty list if the user cancelled.
  Future<List<Attachment>> pickFiles();
}

/// Native file picker on Android, iOS and the web (`file_selector`).
final class FileSelectorAttachmentPicker implements AttachmentPicker {
  const FileSelectorAttachmentPicker();

  @override
  Future<List<Attachment>> pickFiles() async {
    final files = await openFiles();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return [
      for (final (index, file) in files.indexed)
        Attachment(
          id: 'local-$stamp-$index',
          fileName: file.name,
          mimeType: file.mimeType ?? 'application/octet-stream',
          sizeBytes: await file.length(),
        ),
    ];
  }
}

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => const FileSelectorAttachmentPicker(),
);
