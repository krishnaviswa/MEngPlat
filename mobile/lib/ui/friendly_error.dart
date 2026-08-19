import '../core/network/api_exception.dart';

/// Maps Dio/timeout/exception noise to a short line a person can act on.
String friendlyMessage(Object error) {
  if (error is ApiException) return error.message;
  final text = error.toString();
  if (text.contains('receiveTimeout') ||
      text.contains('took longer than') ||
      text.contains('connectionTimeout') ||
      text.contains('Connecting timed out')) {
    return 'That took too long. Check your connection and try again.';
  }
  if (text.contains('SocketException') || text.contains('Failed host lookup') || text.contains('Network is unreachable')) {
    return 'You appear to be offline. Try again when you have a connection.';
  }
  if (text.startsWith('Exception: ')) return text.substring(11);
  if (text.startsWith('ApiException: ')) return text.substring(14);
  return text;
}
