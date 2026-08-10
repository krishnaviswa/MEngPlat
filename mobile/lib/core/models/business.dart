class Category {
  const Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  final String id;
  final String name;
  final String slug;
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    this.state,
    required this.averageRating,
    required this.reviewCount,
    this.description,
    this.categories = const [],
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      city: json['city'] as String,
      state: json['state'] as String?,
      averageRating: (json['average_rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      description: json['description'] as String?,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String slug;
  final String city;
  final String? state;
  final double averageRating;
  final int reviewCount;
  final String? description;
  final List<Category> categories;
}
