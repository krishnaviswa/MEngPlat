/// Query params for `GET /api/v1/search/businesses` (S-028). Pagination
/// (`page`) is applied by [SearchController], not stored here, so changing
/// filters always resets to page 1.
class SearchQuery {
  const SearchQuery({
    this.q,
    this.city,
    this.category,
    this.minRating,
    this.lat,
    this.lng,
    this.radiusKm = defaultRadiusKm,
    this.sort = defaultSort,
  });

  static const pageSize = 20;
  static const defaultRadiusKm = 10.0;
  static const defaultSort = 'rating';

  final String? q;
  final String? city;

  /// Category slug from `GET /businesses/categories/all`.
  final String? category;
  final double? minRating;
  final double? lat;
  final double? lng;
  final double radiusKm;

  /// `rating` | `name` | `reviews`
  final String sort;

  bool get hasLocation => lat != null && lng != null;

  SearchQuery copyWith({
    String? q,
    String? city,
    String? category,
    double? minRating,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sort,
    bool clearQuery = false,
    bool clearCity = false,
    bool clearCategory = false,
    bool clearMinRating = false,
    bool clearLocation = false,
  }) {
    return SearchQuery(
      q: clearQuery ? null : (q ?? this.q),
      city: clearCity ? null : (city ?? this.city),
      category: clearCategory ? null : (category ?? this.category),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      lat: clearLocation ? null : (lat ?? this.lat),
      lng: clearLocation ? null : (lng ?? this.lng),
      radiusKm: radiusKm ?? this.radiusKm,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchQuery &&
        other.q == q &&
        other.city == city &&
        other.category == category &&
        other.minRating == minRating &&
        other.lat == lat &&
        other.lng == lng &&
        other.radiusKm == radiusKm &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(q, city, category, minRating, lat, lng, radiusKm, sort);
}
