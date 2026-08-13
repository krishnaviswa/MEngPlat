import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import 'review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(apiClientProvider)),
);

/// One instance per `businessId` -- the single in-memory source of truth for
/// that business's reviews (Architect spec, S-023 "Cache / side effects").
class ReviewsController extends AutoDisposeFamilyAsyncNotifier<List<ReviewResponse>, String> {
  final Set<String> _likedThisSession = {};
  final Set<String> reportedIds = {};

  @override
  FutureOr<List<ReviewResponse>> build(String businessId) {
    return ref.watch(reviewRepositoryProvider).listForBusiness(businessId);
  }

  Future<void> likeReview(String reviewId) async {
    if (_likedThisSession.contains(reviewId)) return;
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data([
        for (final review in previous)
          if (review.id == reviewId) review.rebuild((b) => b.likeCount = review.likeCount + 1) else review,
      ]);
    }
    try {
      await ref.read(reviewRepositoryProvider).likeReview(reviewId);
      _likedThisSession.add(reviewId);
    } catch (error, stack) {
      if (previous != null) state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> reportReview({required String reviewId, required String reason}) async {
    await ref.read(reviewRepositoryProvider).reportReview(reviewId: reviewId, reason: reason);
    reportedIds.add(reviewId);
    final current = state.valueOrNull;
    if (current != null) state = AsyncValue.data(current);
  }

  /// Creates the review and prepends it to the list on success so it appears
  /// at the top without a refetch (AC8). Rethrows on failure so the form
  /// sheet can show an inline error and keep the entered fields (AC11).
  Future<ReviewResponse> createReview({
    required int rating,
    String? title,
    required String body,
  }) async {
    final review = await ref.read(reviewRepositoryProvider).createReview(
          businessId: arg,
          rating: rating,
          title: title,
          body: body,
        );
    final current = state.valueOrNull ?? const <ReviewResponse>[];
    state = AsyncValue.data([review, ...current]);
    return review;
  }

  /// Uploads one photo for [reviewId] and, on success, merges its URL into
  /// that review's `photoUrls` in place. Throws on failure -- callers (the
  /// review form sheet) decide how to surface a non-blocking warning; the
  /// already-posted review in [state] is never touched by a failed upload
  /// (AC9).
  Future<void> uploadPhoto({required String reviewId, required String filePath}) async {
    final photo = await ref.read(reviewRepositoryProvider).uploadReviewPhoto(
          reviewId: reviewId,
          filePath: filePath,
        );
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final review in current)
        if (review.id == reviewId)
          review.rebuild((b) => b..photoUrls.add(photo.url))
        else
          review,
    ]);
  }
}

final reviewsControllerProvider =
    AsyncNotifierProvider.autoDispose.family<ReviewsController, List<ReviewResponse>, String>(
  ReviewsController.new,
);

/// Whether [userId] already has a review among [reviews] -- derived, not
/// fetched separately (S-023 AC10 / Architect spec).
bool hasAlreadyReviewed(List<ReviewResponse> reviews, String? userId) {
  if (userId == null) return false;
  return reviews.any((review) => review.authorId == userId);
}
