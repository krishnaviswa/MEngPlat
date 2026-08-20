import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/reviews/review_form_sheet.dart';
import 'package:merchanthub_mobile/features/reviews/review_providers.dart';
import 'package:merchanthub_mobile/features/reviews/review_repository.dart';

/// S-023 AC7/AC8/AC11: rating/comment validation gates the submit action,
/// a successful submit closes the sheet with a confirmation, and a failed
/// submit shows an inline error while preserving the entered fields.

ReviewResponse _review({required String id, required String authorId, int rating = 5, String? title, String? body}) {
  return ReviewResponse((b) => b
    ..id = id
    ..businessId = 'biz-1'
    ..authorId = authorId
    ..rating = rating
    ..title = title
    ..body = body ?? 'A sufficiently long review body for testing.'
    ..status = ReviewStatus.active
    ..likeCount = 0
    ..createdAt = DateTime.utc(2026, 1, 1));
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository({this.createError}) : super(ApiClient());

  final Object? createError;
  int createCalls = 0;

  @override
  Future<List<ReviewResponse>> listForBusiness(String businessId) async => [];

  @override
  Future<ReviewResponse> createReview({
    required String businessId,
    required int rating,
    String? title,
    required String body,
  }) async {
    createCalls++;
    final error = createError;
    if (error != null) throw error;
    return _review(id: 'new-review', authorId: 'me', rating: rating, title: title, body: body);
  }
}

Future<ProviderContainer> _settledContainer(ReviewRepository repository) async {
  final container = ProviderContainer(overrides: [reviewRepositoryProvider.overrideWithValue(repository)]);
  // Settle the controller's initial (empty) build before interacting, same
  // sequencing the real form relies on.
  await container.read(reviewsControllerProvider('biz-1').future);
  return container;
}

Future<void> _openSheet(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ReviewFormSheet.show(context, businessId: 'biz-1'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('submit stays disabled until a rating and a non-empty comment are provided', (tester) async {
    final container = await _settledContainer(_FakeReviewRepository());
    addTearDown(container.dispose);
    await _openSheet(tester, container);

    FilledButton submitButton() => tester.widget<FilledButton>(find.byKey(const Key('submitReviewButton')));
    expect(submitButton().onPressed, isNull, reason: 'no rating, no comment yet');

    await tester.enterText(find.byKey(const Key('reviewBodyField')), '🙂');
    await tester.pump();
    expect(submitButton().onPressed, isNull, reason: 'comment without a rating is not enough');

    await tester.tap(find.byKey(const Key('ratingStar4')));
    await tester.pump();
    expect(submitButton().onPressed, isNotNull, reason: 'rating + 1+ char body (smiley OK)');
  });

  testWidgets('a successful submit closes the sheet and shows a success confirmation (AC8)', (tester) async {
    final repository = _FakeReviewRepository();
    final container = await _settledContainer(repository);
    addTearDown(container.dispose);
    await _openSheet(tester, container);

    await tester.tap(find.byKey(const Key('ratingStar5')));
    await tester.enterText(find.byKey(const Key('reviewBodyField')), 'Excellent service and friendly staff.');
    await tester.pump();

    await tester.tap(find.byKey(const Key('submitReviewButton')));
    await tester.pump();
    await tester.pump();
    // Let the modal-bottom-sheet exit transition finish (default ~250ms)
    // without using pumpAndSettle, which would also run the SnackBar's
    // multi-second auto-dismiss timer to completion.
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.createCalls, 1);
    expect(find.text('Write a review'), findsNothing, reason: 'sheet should have closed on success');
    expect(find.text('Review posted'), findsOneWidget);
  });

  testWidgets('a failed submit shows an inline error and preserves entered fields (AC11)', (tester) async {
    final repository = _FakeReviewRepository(createError: ApiException('Network error, try again'));
    final container = await _settledContainer(repository);
    addTearDown(container.dispose);
    await _openSheet(tester, container);

    await tester.tap(find.byKey(const Key('ratingStar4')));
    await tester.enterText(find.byKey(const Key('reviewTitleField')), 'My title');
    await tester.enterText(find.byKey(const Key('reviewBodyField')), 'This review will fail to submit today.');
    await tester.pump();

    await tester.tap(find.byKey(const Key('submitReviewButton')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Network error, try again'), findsOneWidget);
    expect(find.text('Write a review'), findsOneWidget, reason: 'sheet should stay open on failure');
    expect(find.text('My title'), findsOneWidget, reason: 'title must be preserved, not cleared');
    expect(find.text('This review will fail to submit today.'), findsOneWidget, reason: 'body must be preserved');

    // Rating (star 4) must still be selected -- submit should be re-enabled
    // immediately since both requirements remain satisfied.
    final submitButton = tester.widget<FilledButton>(find.byKey(const Key('submitReviewButton')));
    expect(submitButton.onPressed, isNotNull);
  });

  testWidgets(
    'AC10: a stale duplicate submission surfaces the backend\'s clear "already reviewed" message',
    (tester) async {
      final repository = _FakeReviewRepository(
        createError: ApiException('You have already reviewed this business', statusCode: 409),
      );
      final container = await _settledContainer(repository);
      addTearDown(container.dispose);
      await _openSheet(tester, container);

      await tester.tap(find.byKey(const Key('ratingStar3')));
      await tester.enterText(find.byKey(const Key('reviewBodyField')), 'Trying to submit a second time.');
      await tester.pump();

      await tester.tap(find.byKey(const Key('submitReviewButton')));
      await tester.pump();
      await tester.pump();

      expect(find.text('You have already reviewed this business'), findsOneWidget);
    },
  );
}
