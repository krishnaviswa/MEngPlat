import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';

ReviewResponse _review({
  required String id,
  required String authorId,
  int rating = 5,
  String? title,
  String body = 'Great place, loved the food and the service.',
}) {
  return ReviewResponse((b) => b
    ..id = id
    ..businessId = 'biz-1'
    ..authorId = authorId
    ..rating = rating
    ..title = title
    ..body = body
    ..status = ReviewStatus.active
    ..likeCount = 0
    ..createdAt = DateTime.utc(2026, 1, 1));
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(ApiClient());

  @override
  Future<List<ReviewResponse>> listForBusiness(String businessId) async {
    return [_review(id: 'existing-review', authorId: 'other-user')];
  }

  @override
  Future<ReviewResponse> createReview({
    required String businessId,
    required int rating,
    String? title,
    required String body,
  }) async {
    return _review(id: 'new-review', authorId: 'me', rating: rating, title: title, body: body);
  }
}

void main() {
  test('createReview prepends the new review without a refetch', () async {
    final container = ProviderContainer(
      overrides: [reviewRepositoryProvider.overrideWithValue(_FakeReviewRepository())],
    );
    addTearDown(container.dispose);

    // Let the initial build() (listForBusiness) settle first.
    final initial = await container.read(reviewsControllerProvider('biz-1').future);
    expect(initial, hasLength(1));

    final notifier = container.read(reviewsControllerProvider('biz-1').notifier);
    final created = await notifier.createReview(rating: 4, title: 'Nice', body: 'Would come back again, honestly.');

    final state = container.read(reviewsControllerProvider('biz-1')).value!;
    expect(state, hasLength(2));
    expect(state.first.id, created.id);
    expect(state.first.authorId, 'me');
  });

  test('hasAlreadyReviewed matches on authorId', () {
    final reviews = [_review(id: 'r1', authorId: 'user-a')];
    expect(hasAlreadyReviewed(reviews, 'user-a'), isTrue);
    expect(hasAlreadyReviewed(reviews, 'user-b'), isFalse);
    expect(hasAlreadyReviewed(reviews, null), isFalse);
  });
}
