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
    return ApiException(
      _messageFromBody(error.response?.data) ?? error.message ?? 'Something went wrong',
      statusCode: error.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String? _messageFromBody(Object? data) {
  if (data is Map) {
    return _formatDetail(data['detail']);
  }
  if (data is String && data.trim().isNotEmpty) {
    return data;
  }
  return null;
}

String? _formatDetail(Object? detail) {
  if (detail is String && detail.trim().isNotEmpty) {
    return detail;
  }
  if (detail is List) {
    final messages = <String>[];
    for (final item in detail) {
      if (item is Map && item['msg'] is String) {
        messages.add(_stripPydanticPrefix(item['msg'] as String));
      } else if (item is String && item.trim().isNotEmpty) {
        messages.add(item);
      }
    }
    if (messages.isNotEmpty) {
      return messages.join(' ');
    }
  }
  return null;
}

String _stripPydanticPrefix(String msg) {
  const prefix = 'Value error, ';
  return msg.startsWith(prefix) ? msg.substring(prefix.length) : msg;
}
