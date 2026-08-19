import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/admin/admin_copy.dart';

void main() {
  test('S-093 category create error mapping', () {
    expect(categoryCreateErrorMessage(ApiException('x', statusCode: 409), 'Bakery'), 'A category named "Bakery" already exists');
    expect(
      categoryCreateErrorMessage(ApiException('x', statusCode: 403), 'Bakery'),
      "Your session has expired or you don't have permission. Sign in again as an admin.",
    );
    expect(categoryCreateErrorMessage(ApiException('x', statusCode: 500), 'Bakery'), 'Something went wrong on our end. Please try again.');
    expect(categoryCreateErrorMessage(ApiException('offline'), 'Bakery'), 'Network problem — check your connection and try again.');
  });
}
