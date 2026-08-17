import 'package:flutter/material.dart';

enum ReviewSortOption { newest, oldest, highest, lowest }

@immutable
class ReviewListFilter {
  const ReviewListFilter({this.sortBy = ReviewSortOption.newest, this.minRating = 0});

  final ReviewSortOption sortBy;
  final double minRating;

  bool get hasActiveFilter => minRating > 0 || sortBy != ReviewSortOption.newest;
}

Future<ReviewListFilter?> showReviewFilterSheet({
  required BuildContext context,
  required ReviewListFilter initial,
}) {
  return showModalBottomSheet<ReviewListFilter>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReviewFilterSheet(initial: initial),
  );
}

class _ReviewFilterSheet extends StatefulWidget {
  const _ReviewFilterSheet({required this.initial});

  final ReviewListFilter initial;

  @override
  State<_ReviewFilterSheet> createState() => _ReviewFilterSheetState();
}

class _ReviewFilterSheetState extends State<_ReviewFilterSheet> {
  late ReviewSortOption _sortBy = widget.initial.sortBy;
  late double _minRating = widget.initial.minRating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          key: const Key('reviewFilterSheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sort & filter reviews', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReviewSortOption>(
              key: const Key('reviewSortField'),
              decoration: const InputDecoration(labelText: 'Sort'),
              // ignore: deprecated_member_use
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: ReviewSortOption.newest, child: Text('Newest')),
                DropdownMenuItem(value: ReviewSortOption.oldest, child: Text('Oldest')),
                DropdownMenuItem(value: ReviewSortOption.highest, child: Text('Highest rating')),
                DropdownMenuItem(value: ReviewSortOption.lowest, child: Text('Lowest rating')),
              ],
              onChanged: (value) => setState(() => _sortBy = value ?? ReviewSortOption.newest),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              key: const Key('reviewMinRatingField'),
              decoration: const InputDecoration(labelText: 'Minimum rating'),
              // ignore: deprecated_member_use
              value: _minRating,
              items: const [
                DropdownMenuItem(value: 0, child: Text('All')),
                DropdownMenuItem(value: 3, child: Text('3 stars & up')),
                DropdownMenuItem(value: 4, child: Text('4 stars & up')),
                DropdownMenuItem(value: 5, child: Text('5 stars')),
              ],
              onChanged: (value) => setState(() => _minRating = value ?? 0),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('clearReviewFiltersSheetButton'),
                    onPressed: () => Navigator.of(context).pop(const ReviewListFilter()),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('applyReviewFiltersButton'),
                    onPressed: () => Navigator.of(context).pop(
                      ReviewListFilter(sortBy: _sortBy, minRating: _minRating),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
