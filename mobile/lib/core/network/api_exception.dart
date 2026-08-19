import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('That took too long. Check your connection and try again.');
      case DioExceptionType.connectionError:
        return ApiException('You appear to be offline. Try again when you have a connection.');
      default:
        break;
    }
    final data = error.response?.data;
    final detail = data is Map<String, dynamic> ? data['detail'] : null;
    return ApiException(
      detail is String ? detail : (error.message ?? 'Something went wrong'),
      statusCode: error.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
