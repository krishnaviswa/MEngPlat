import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException error) {
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
