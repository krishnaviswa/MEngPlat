import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/features/reviews/review_card.dart';

/// S-023 AC2: any AI sentiment badge/summary must be visibly labeled as an
/// AI-generated suggestion, never a verified fact, mirroring
/// `frontend/src/components/ReviewCard.tsx`'s "AI: {sentiment}" badge and
/// "AI summary (suggestion): ..." text.

ReviewResponse _review({
  String? title,
  String? fullName,
  Sentiment? sentiment,
  String? summary,
  String? replyBody,
  int likeCount = 0,
  String? body,
  List<String>? photoUrls,
}) {
  return ReviewResponse((b) {
    b
      ..id = 'review-1'
      ..businessId = 'biz-1'
      ..authorId = 'author-1'
      ..rating = 5
      ..title = title
      ..body = body ?? 'Really enjoyed the visit, would recommend to others.'
      ..status = ReviewStatus.active
      ..likeCount = likeCount
      ..createdAt = DateTime.utc(2026, 1, 1);
    if (photoUrls != null) {
      b.photoUrls.addAll(photoUrls);
    }
    if (fullName != null) {
      b.author.replace(UserResponse((u) => u
        ..id = 'author-1'
        ..email = 'author@example.com'
        ..fullName = fullName
        ..role = UserRole.customer
        ..isActive = true
        ..createdAt = DateTime.utc(2026, 1, 1)));
    }
    if (sentiment != null || summary != null) {
      b.aiAnalysis.replace(AIAnalysisResponse((a) => a
        ..id = 'analysis-1'
        ..analysisType = 'review'
        ..provider = 'mock'
        ..sentiment = sentiment
        ..summary = summary));
    }
    if (replyBody != null) {
      b.reply.replace(ReplyResponse((r) => r
        ..id = 'reply-1'
        ..body = replyBody
        ..createdAt = DateTime.utc(2026, 1, 2)));
    }
  });
}

Future<void> _pump(WidgetTester tester, ReviewResponse review) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: ReviewCard(review: review))));
}

void main() {
  testWidgets('shows an "AI: {sentiment}" badge when ai_analysis has a sentiment', (tester) async {
    await _pump(tester, _review(sentiment: Sentiment.positive));

    expect(find.text('AI: positive'), findsOneWidget);
  });

  testWidgets('shows AI summary text prefixed as a suggestion, not a fact', (tester) async {
    await _pump(tester, _review(summary: 'Customers seem happy with the service.'));

    expect(find.textContaining('AI summary (suggestion):'), findsOneWidget);
    expect(find.textContaining('Customers seem happy with the service.'), findsOneWidget);
  });

  testWidgets('renders no AI badge or summary when ai_analysis is absent', (tester) async {
    await _pump(tester, _review());

    expect(find.textContaining('AI:'), findsNothing);
    expect(find.textContaining('AI summary'), findsNothing);
  });

  testWidgets('falls back to "Customer" when the author is unavailable', (tester) async {
    await _pump(tester, _review());

    expect(find.text('Customer'), findsOneWidget);
  });

  testWidgets('shows the reviewer\'s name when the author is present', (tester) async {
    await _pump(tester, _review(fullName: 'Jane Doe'));

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Customer'), findsNothing);
  });

  testWidgets('shows the review title when present', (tester) async {
    await _pump(tester, _review(title: 'Great spot'));

    expect(find.text('Great spot'), findsOneWidget);
  });

  testWidgets('S-030 AC7: shows merchant reply when present', (tester) async {
    await _pump(tester, _review(replyBody: 'Thanks for coming in!'));

    expect(find.byKey(const Key('merchantReplyBlock')), findsOneWidget);
    expect(find.text('Response from the business'), findsOneWidget);
    expect(find.text('Thanks for coming in!'), findsOneWidget);
    expect(find.byKey(const Key('reviewReplyButton')), findsNothing);
  });

  testWidgets('S-030 AC8: omits reply block and composer when there is no reply', (tester) async {
    await _pump(tester, _review());

    expect(find.byKey(const Key('merchantReplyBlock')), findsNothing);
    expect(find.byKey(const Key('reviewReplyButton')), findsNothing);
  });

  testWidgets('S-030 AC1: like control shows like_count', (tester) async {
    await _pump(tester, _review(likeCount: 3));

    expect(find.byKey(const Key('reviewLikeButton')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('S-030 AC4: Report opens a reason field; submit disabled under 10 chars', (tester) async {
    var reported = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewCard(
            review: _review(),
            onReport: (reason) async {
              reported = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('reviewReportButton')));
    await tester.pump();
    expect(find.byKey(const Key('reviewReportReason')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reviewReportReason')), 'too short');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('reviewReportSubmit'))).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('reviewReportReason')), 'This is long enough to report.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('reviewReportSubmit')));
    await tester.pump();
    expect(reported, isTrue);
  });

  testWidgets('S-031 M-53: reply composer when canReply and no existing reply', (tester) async {
    String? posted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewCard(
            review: _review(),
            showActions: false,
            canReply: true,
            onReply: (body) async {
              posted = body;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('reviewReplyButton')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('reviewReplyBody')), 'Glad you enjoyed it.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('reviewReplySubmit')));
    await tester.pump();
    expect(posted, 'Glad you enjoyed it.');
  });

  testWidgets('S-030 AC5: reported placeholder replaces the card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewCard(review: _review(), reported: true),
        ),
      ),
    );
    expect(find.byKey(const Key('reviewReportedPlaceholder')), findsOneWidget);
    expect(find.byKey(const Key('reviewLikeButton')), findsNothing);
  });

  testWidgets('S-030 AC6: guest Report calls onRequireLogin', (tester) async {
    var login = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewCard(
            review: _review(),
            onRequireLogin: () => login = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('reviewReportButton')));
    await tester.pump();
    expect(login, isTrue);
    expect(find.byKey(const Key('reviewReportReason')), findsNothing);
  });

  group('S-058 AC4: truncation + Read more/less toggle', () {
    final longBody = 'A' * 281; // exceeds the 280-char threshold

    testWidgets('a long body renders clamped to 3 lines with a Read more toggle', (tester) async {
      await _pump(tester, _review(body: longBody));

      final bodyFinder = find.byWidgetPredicate((w) => w is Text && w.data == longBody);
      final textWidget = tester.widget<Text>(bodyFinder);
      expect(textWidget.maxLines, 3);
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(find.byKey(const Key('reviewReadMoreToggle')), findsOneWidget);
      expect(find.text('Read more'), findsOneWidget);
    });

    testWidgets('tapping Read more expands the body and flips the label to Read less', (tester) async {
      await _pump(tester, _review(body: longBody));

      await tester.tap(find.byKey(const Key('reviewReadMoreToggle')));
      await tester.pump();

      final bodyFinder = find.byWidgetPredicate((w) => w is Text && w.data == longBody);
      final expanded = tester.widget<Text>(bodyFinder);
      expect(expanded.maxLines, isNull);
      expect(expanded.overflow, TextOverflow.visible);
      expect(find.text('Read less'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);

      // Tapping again collapses it back.
      await tester.tap(find.byKey(const Key('reviewReadMoreToggle')));
      await tester.pump();
      final collapsed = tester.widget<Text>(bodyFinder);
      expect(collapsed.maxLines, 3);
      expect(find.text('Read more'), findsOneWidget);
    });

    testWidgets('a short body renders with no Read more toggle', (tester) async {
      await _pump(tester, _review(body: 'A short review body.'));

      expect(find.byKey(const Key('reviewReadMoreToggle')), findsNothing);
    });
  });

  group('S-058 AC5: photo thumbnail opens a full-screen lightbox', () {
    testWidgets('tapping a review photo thumbnail opens photoLightbox', (tester) async {
      // ReviewCard's `Image.network` thumbnails (unlike PhotoGallery's) have
      // no `errorBuilder`, so the test environment's expected-to-fail
      // NetworkImage requests (no real network access under flutter_test)
      // surface as unhandled FlutterError zone errors rather than a widget
      // fallback. That's orthogonal to what AC5 tests (does tapping a
      // thumbnail open the lightbox), so ignore just that expected class of
      // error for this test.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await _pump(
        tester,
        _review(photoUrls: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg']),
      );

      expect(find.byKey(const Key('reviewPhotoThumb_0')), findsOneWidget);
      expect(find.byKey(const Key('photoLightbox')), findsNothing);

      await tester.tap(find.byKey(const Key('reviewPhotoThumb_0')));
      await tester.pump();

      expect(find.byKey(const Key('photoLightbox')), findsOneWidget);
    });

    testWidgets('no photo strip is rendered when a review has no photos', (tester) async {
      await _pump(tester, _review());

      expect(find.byKey(const Key('reviewPhotoThumb_0')), findsNothing);
    });
  });
}
