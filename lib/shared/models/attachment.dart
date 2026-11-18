import 'package:flutter/foundation.dart';

/// Metadata for a file attached to a message or draft.
///
/// File contents are never held in this entity; they will be downloaded on
/// demand from the Go API.
@immutable
class Attachment {
  const Attachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  @override
  bool operator ==(Object other) =>
      other is Attachment &&
      other.id == id &&
      other.fileName == fileName &&
      other.mimeType == mimeType &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(id, fileName, mimeType, sizeBytes);
}
