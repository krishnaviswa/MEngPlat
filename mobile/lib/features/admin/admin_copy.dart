import '../../core/network/api_exception.dart';

String categoryCreateErrorMessage(Object error, String name) {
  if (error is ApiException) {
    if (error.statusCode == 409) return 'A category named "$name" already exists';
    if (error.statusCode == 401 || error.statusCode == 403) {
      return "Your session has expired or you don't have permission. Sign in again as an admin.";
    }
    if (error.statusCode != null) return 'Something went wrong on our end. Please try again.';
  }
  return 'Network problem — check your connection and try again.';
}
