import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/reviews/rating_stars.dart';

/// S-058 AC6: a readonly `RatingStars` (no `onChanged`) renders a half-star
/// glyph for the fractional portion of a rating, rounded to the nearest
/// half-star (`(rating * 2).round() / 2`), rather than a whole-star rounding
/// or a single static icon. AC7: the interactive picker (`onChanged` set)
/// stays whole-star only, untouched by the half-star logic.

int _iconCount(WidgetTester tester, IconData icon) =>
    tester.widgetList<Icon>(find.byWidgetPredicate((w) => w is Icon && w.icon == icon)).length;

void main() {
  testWidgets('AC6: rating 4.3 rounds to displayValue 4.5 -> 4 full + 1 half + 0 empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RatingStars(rating: 4.3))));

    expect(_iconCount(tester, Icons.star), 4);
    expect(_iconCount(tester, Icons.star_half), 1);
    expect(_iconCount(tester, Icons.star_border), 0);
  });

  testWidgets('AC6: rating 3.7 rounds to displayValue 3.5 -> 3 full + 1 half + 1 empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RatingStars(rating: 3.7))));

    expect(_iconCount(tester, Icons.star), 3);
    expect(_iconCount(tester, Icons.star_half), 1);
    expect(_iconCount(tester, Icons.star_border), 1);
  });

  testWidgets('AC6: a whole-number rating renders no half-star', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RatingStars(rating: 3))));

    expect(_iconCount(tester, Icons.star), 3);
    expect(_iconCount(tester, Icons.star_half), 0);
    expect(_iconCount(tester, Icons.star_border), 2);
  });

  testWidgets('AC7: the interactive picker (onChanged set) stays whole-star only, no half-star icon', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RatingStars(rating: 3.7, onChanged: (value) => selected = value),
        ),
      ),
    );

    // Interactive branch renders IconButtons keyed ratingStar1..5, never a
    // star_half icon regardless of the fractional `rating` passed in.
    expect(_iconCount(tester, Icons.star_half), 0);
    expect(find.byKey(const Key('ratingStar4')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ratingStar4')));
    expect(selected, 4);
  });
}
