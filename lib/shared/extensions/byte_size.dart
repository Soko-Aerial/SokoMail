/// Human-readable file sizes: 512 B, 870 KB, 3.2 MB.
extension ByteSize on int {
  String toFileSizeLabel() {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).round()} KB';
    return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
