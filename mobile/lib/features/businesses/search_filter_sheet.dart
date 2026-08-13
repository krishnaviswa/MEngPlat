import 'package:flutter/material.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'search_query.dart';

Future<SearchQuery?> showSearchFilterSheet({
  required BuildContext context,
  required SearchQuery query,
  required List<String> cities,
  required List<CategoryResponse> categories,
}) {
  return showModalBottomSheet<SearchQuery>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SearchFilterSheet(
      initial: query,
      cities: cities,
      categories: categories,
    ),
  );
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet({
    required this.initial,
    required this.cities,
    required this.categories,
  });

  final SearchQuery initial;
  final List<String> cities;
  final List<CategoryResponse> categories;

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late String? _city = widget.initial.city;
  late String? _category = widget.initial.category;
  late double? _minRating = widget.initial.minRating;
  late String _sort = widget.initial.sort;
  late double _radiusKm = widget.initial.radiusKm;

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
          key: const Key('filtersSheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key: const Key('cityFilter'),
              decoration: const InputDecoration(labelText: 'City'),
              // ignore: deprecated_member_use
              value: _city,
              items: [
                const DropdownMenuItem(value: null, child: Text('Any city')),
                for (final city in widget.cities) DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: const Key('categoryFilter'),
              decoration: const InputDecoration(labelText: 'Category'),
              // ignore: deprecated_member_use
              value: _category,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final category in widget.categories)
                  DropdownMenuItem(value: category.slug, child: Text(category.name)),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double?>(
              key: const Key('minRatingFilter'),
              decoration: const InputDecoration(labelText: 'Minimum rating'),
              // ignore: deprecated_member_use
              value: _minRating,
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: 3, child: Text('3+')),
                DropdownMenuItem(value: 4, child: Text('4+')),
                DropdownMenuItem(value: 4.5, child: Text('4.5+')),
              ],
              onChanged: (value) => setState(() => _minRating = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('sortFilter'),
              decoration: const InputDecoration(labelText: 'Sort'),
              // ignore: deprecated_member_use
              value: _sort,
              items: const [
                DropdownMenuItem(value: 'rating', child: Text('Rating')),
                DropdownMenuItem(value: 'name', child: Text('Name')),
                DropdownMenuItem(value: 'reviews', child: Text('Reviews')),
              ],
              onChanged: (value) => setState(() => _sort = value ?? SearchQuery.defaultSort),
            ),
            if (widget.initial.hasLocation) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                key: const Key('radiusFilter'),
                decoration: const InputDecoration(labelText: 'Radius (km)'),
                // ignore: deprecated_member_use
                value: _radiusKm,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 km')),
                  DropdownMenuItem(value: 10, child: Text('10 km')),
                  DropdownMenuItem(value: 25, child: Text('25 km')),
                ],
                onChanged: (value) => setState(() => _radiusKm = value ?? SearchQuery.defaultRadiusKm),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('clearFiltersButton'),
                    onPressed: () {
                      Navigator.of(context).pop(
                        widget.initial.copyWith(
                          clearCity: true,
                          clearCategory: true,
                          clearMinRating: true,
                          sort: SearchQuery.defaultSort,
                          radiusKm: SearchQuery.defaultRadiusKm,
                        ),
                      );
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('applyFiltersButton'),
                    onPressed: () {
                      Navigator.of(context).pop(
                        widget.initial.copyWith(
                          city: _city,
                          category: _category,
                          minRating: _minRating,
                          sort: _sort,
                          radiusKm: _radiusKm,
                          clearCity: _city == null,
                          clearCategory: _category == null,
                          clearMinRating: _minRating == null,
                        ),
                      );
                    },
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
