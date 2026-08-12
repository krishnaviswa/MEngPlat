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
}) {
  return ReviewResponse((b) {
    b
      ..id = 'review-1'
      ..businessId = 'biz-1'
      ..authorId = 'author-1'
      ..rating = 5
      ..title = title
      ..body = 'Really enjoyed the visit, would recommend to others.'
      ..status = ReviewStatus.active
      ..likeCount = 0
      ..createdAt = DateTime.utc(2026, 1, 1);
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
}
