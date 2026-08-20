import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_provider.dart';

class SupportRepository {
  SupportRepository(this._client);

  final ApiClient _client;

  Future<SupportContactResponse> contact() async {
    try {
      final response = await _client.authFreeApi.getSupportApi().supportContactApiV1SupportContactGet();
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SupportTicketResponse> createTicket({
    required String name,
    required String phone,
    required String issue,
    String? businessId,
  }) async {
    try {
      final response = await _client.api.getSupportApi().createSupportTicketApiV1SupportTicketsPost(
            supportTicketCreate: SupportTicketCreate((b) => b
              ..name = name
              ..phone = phone
              ..issue = issue
              ..businessId = businessId),
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<SupportTicketResponse>> myTickets() async {
    try {
      final response = await _client.api.getSupportApi().listMySupportTicketsApiV1SupportTicketsMineGet();
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /support-tickets/{id}` is not on the generated client yet.
  Future<SupportTicketResponse> getTicket(String ticketId) async {
    try {
      final response = await _client.api.dio.get<Object>('/api/v1/support-tickets/$ticketId');
      return standardSerializers.deserialize(
        response.data,
        specifiedType: const FullType(SupportTicketResponse),
      ) as SupportTicketResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<BusinessReportResponse>> myReports() async {
    try {
      final response = await _client.api.getSupportApi().listMyBusinessReportsApiV1BusinessReportsMineGet();
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(apiClientProvider)),
);
