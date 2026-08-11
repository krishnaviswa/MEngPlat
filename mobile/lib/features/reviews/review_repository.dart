import 'package:dio/dio.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class ReviewRepository {
  ReviewRepository(this._client);

  final ApiClient _client;

  /// Public endpoint (no auth required) -- reachable from the anonymous
  /// business detail screen carve-out (ADR-003, S-023 AC13).
  Future<List<ReviewResponse>> listForBusiness(String businessId) async {
    try {
      final response =
          await _client.api.getReviewsApi().listBusinessReviewsApiV1ReviewsBusinessBusinessIdGet(
                businessId: businessId,
              );
      return response.data!.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ReviewResponse> createReview({
    required String businessId,
    required int rating,
    String? title,
    required String body,
  }) async {
    try {
      final response = await _client.api.getReviewsApi().createReviewApiV1ReviewsPost(
            reviewCreate: ReviewCreate((b) => b
              ..businessId = businessId
              ..rating = rating
              ..title = title
              ..body = body),
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Uploads a single review photo from a device file path (as returned by
  /// `image_picker`). Failures are surfaced to the caller as an
  /// [ApiException] -- [ReviewsController.uploadPhoto] never rolls back the
  /// already-created review because of one (S-023 AC9).
  Future<PhotoResponse> uploadReviewPhoto({
    required String reviewId,
    required String filePath,
  }) async {
    try {
      // Path-safe basename: Windows pickers may return `\` separators.
      final filename = filePath.replaceAll(r'\', '/').split('/').last;
      final file = await MultipartFile.fromFile(filePath, filename: filename);
      final response = await _client.api.getPhotosApi().uploadPhotoApiV1PhotosUploadPost(
            file: file,
            reviewId: reviewId,
            photoType: 'review',
          );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
