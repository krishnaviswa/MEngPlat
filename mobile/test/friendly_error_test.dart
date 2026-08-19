import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';

void main() {
  test('timeout Dio errors become a short retry line', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.receiveTimeout,
      message: 'The request took longer than 0:00:30.000000 to receive data.',
    );
    expect(
      ApiException.fromDioException(error).message,
      'That took too long. Check your connection and try again.',
    );
    expect(friendlyMessage(error), 'That took too long. Check your connection and try again.');
  });

  test('Exception prefix is stripped', () {
    expect(friendlyMessage(Exception('403: not your business')), '403: not your business');
  });

  test('FastAPI 422 detail list becomes a short validation line', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/me'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/auth/me'),
        statusCode: 422,
        data: {
          'detail': [
            {
              'type': 'value_error',
              'loc': ['body', 'national_id_number'],
              'msg': 'Value error, Aadhaar must be exactly 12 digits',
            },
          ],
        },
      ),
      message: 'This exception was thrown because the response has a status code of 422',
    );
    expect(ApiException.fromDioException(error).message, 'Aadhaar must be exactly 12 digits');
    expect(friendlyMessage(error), 'Aadhaar must be exactly 12 digits');
  });
}
