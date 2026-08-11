import 'package:flutter/material.dart';

/// A row of 1-5 star icons. Readonly by default (review display); pass
/// [onChanged] to make it interactive (the review form's rating picker).
/// Shared by [ReviewCard] and [ReviewFormSheet] per the Architect spec.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.onChanged,
    this.size = 18,
    super.key,
  });

  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  bool get _readonly => onChanged == null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          _readonly
              ? Icon(
                  i <= rating ? Icons.star : Icons.star_border,
                  size: size,
                  color: Colors.amber,
                )
              : IconButton(
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
