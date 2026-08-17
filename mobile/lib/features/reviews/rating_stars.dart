import 'package:flutter/material.dart';

/// A row of 1-5 star icons. Readonly by default (review display, half-star
/// aware per S-058); pass [onChanged] to make it interactive (the review
/// form's rating picker, whole-star only). Shared by [ReviewCard] and
/// [ReviewFormSheet] per the Architect spec.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.onChanged,
    this.size = 18,
    super.key,
  });

  final num rating;
  final ValueChanged<int>? onChanged;
  final double size;

  bool get _readonly => onChanged == null;

  @override
  Widget build(BuildContext context) {
    if (_readonly) {
      final displayValue = (rating * 2).round() / 2;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              displayValue >= i
                  ? Icons.star
                  : displayValue >= i - 0.5
                      ? Icons.star_half
                      : Icons.star_border,
              size: size,
              color: Colors.amber,
            ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            key: Key('ratingStar$i'),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: size + 8, minHeight: size + 8),
            iconSize: size,
            color: Colors.amber,
            icon: Icon(i <= rating ? Icons.star : Icons.star_border),
            onPressed: () => onChanged!(i),
          ),
      ],
    );
  }
}
