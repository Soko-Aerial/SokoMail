import 'package:material_ui/material_ui.dart';
import 'package:sokomail/shared/extensions/byte_size.dart';
import 'package:sokomail/shared/models/attachment.dart';

/// Attachment card: coloured file-type badge, name, size and download.
class AttachmentCard extends StatelessWidget {
  const AttachmentCard({
    super.key,
    required this.attachment,
    required this.onDownload,
    this.width = 320,
  });

  final Attachment attachment;
  final VoidCallback onDownload;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          FileTypeBadge(attachment: attachment),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  attachment.sizeBytes.toFileSizeLabel(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Download ${attachment.fileName}',
            icon: const Icon(Icons.download_rounded),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }
}

/// Rounded square with the file extension ("PDF", "XLSX", ...).
class FileTypeBadge extends StatelessWidget {
  const FileTypeBadge({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final name = attachment.fileName;
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 || dot == name.length - 1
        ? 'FILE'
        : name.substring(dot + 1).toUpperCase();
    final label = extension.length > 4 ? extension.substring(0, 4) : extension;

    // Conventional file-type colours, all dark enough for white text.
    final colour = switch (extension) {
      'PDF' => const Color(0xFFC62828),
      'XLS' || 'XLSX' || 'CSV' => const Color(0xFF1E7B45),
      'DOC' || 'DOCX' => const Color(0xFF2B5797),
      'PNG' || 'JPG' || 'JPEG' || 'GIF' => const Color(0xFF536537),
      _ => const Color(0xFF5B6458),
    };

    return ExcludeSemantics(
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
