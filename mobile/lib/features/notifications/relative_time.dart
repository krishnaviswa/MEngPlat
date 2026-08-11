/// Small hand-rolled "Xm/h/d ago" helper -- no `intl`/`timeago` dependency
/// exists in this project yet, and S-025 doesn't need one just for this.
String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final reference = (now ?? DateTime.now()).toUtc();
  final diff = reference.difference(dateTime.toUtc());

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
  return '${diff.inDays ~/ 365}y ago';
}
