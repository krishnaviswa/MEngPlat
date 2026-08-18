import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../businesses/business_list_provider.dart';
import '../businesses/search_query.dart';
import '../reviews/review_providers.dart';
import 'social_proof_data.dart';

const _featuredCap = 6;
const _heroPhotoCap = 6;
const _voiceBusinessCap = 3;

class CityIndexItem {
  const CityIndexItem({required this.name, required this.count});

  final String name;
  final int count;
}

class CategoryIndexItem {
  const CategoryIndexItem({required this.category, required this.count});

  final CategoryResponse category;
  final int count;
}

class ReviewVoiceItem {
  const ReviewVoiceItem({required this.business, required this.review});

  final BusinessResponse business;
  final ReviewResponse review;
}

/// Aggregated public home payload (S-064). Mirrors web `page.tsx` assembly.
class HomePayload {
  const HomePayload({
    required this.socialProof,
    required this.heroPhotos,
    required this.stats,
    required this.cities,
    required this.categories,
    required this.featured,
    required this.featuredCity,
    required this.voices,
    this.loadError,
  });

  final List<SocialProofEntry> socialProof;
  final List<String> heroPhotos;
  final PublicPlatformStats? stats;
  final List<CityIndexItem> cities;
  final List<CategoryIndexItem> categories;
  final List<BusinessResponse> featured;
  final String? featuredCity;
  final List<ReviewVoiceItem> voices;
  final String? loadError;
}

final homePayloadProvider = FutureProvider.autoDispose<HomePayload>((ref) async {
  final businesses = ref.watch(businessRepositoryProvider);
  final reviews = ref.watch(reviewRepositoryProvider);

  List<BusinessResponse> listed = const [];
  List<String> cityNames = const [];
  List<CategoryResponse> categoryList = const [];
  PublicPlatformStats? stats;
  final loadErrors = <String>[];

  Future<void> tryCall(String label, Future<void> Function() run) async {
    try {
      await run();
    } catch (error) {
      loadErrors.add('$label: $error');
    }
  }

  await Future.wait([
    tryCall('businesses.list', () async {
      listed = await businesses.listPublic();
    }),
    tryCall('businesses.cities', () async {
      cityNames = await businesses.listCities();
    }),
    tryCall('businesses.categoriesAll', () async {
      categoryList = await businesses.listCategories();
    }),
    tryCall('businesses.stats', () async {
      stats = await businesses.publicStats();
    }),
  ]);

  var socialProof = kSocialProofFallback;
  try {
    final seeded = await businesses.listPublic(slugs: kSocialProofSlugs.join(','));
    final bySlug = {for (final b in seeded) b.slug: b};
    final matched = kSocialProofSlugs
        .map((slug) => bySlug[slug])
        .whereType<BusinessResponse>()
        .map(
          (b) => SocialProofEntry(
            name: b.name,
            initial: initialsFor(b.name),
            logoUrl: b.logoUrl,
            storefrontUrl: b.storefrontUrl,
          ),
        )
        .toList();
    if (matched.isNotEmpty) socialProof = matched;
  } catch (_) {
    // Keep fallback — AC 5.
  }

  final featuredCity = cityNames.isNotEmpty ? cityNames.first : null;
  var featured = listed;
  if (featuredCity != null) {
    try {
      final byCity = await businesses.searchBusinesses(query: SearchQuery(city: featuredCity));
      if (byCity.isNotEmpty) featured = byCity;
    } catch (_) {
      // Keep `listed`.
    }
  }
  featured = featured.take(_featuredCap).toList();

  final cityCounts = <String, int>{};
  for (final b in listed) {
    final city = b.city;
    if (city.isEmpty) continue;
    cityCounts[city] = (cityCounts[city] ?? 0) + 1;
  }
  final cities = [
    for (final name in cityNames) CityIndexItem(name: name, count: cityCounts[name] ?? 0),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });

  final categoryCounts = <String, int>{};
  for (final b in listed) {
    for (final c in b.categories ?? const <CategoryResponse>[]) {
      categoryCounts[c.slug] = (categoryCounts[c.slug] ?? 0) + 1;
    }
  }
  final categories = [
    for (final category in categoryList)
      CategoryIndexItem(category: category, count: categoryCounts[category.slug] ?? 0),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.category.name.compareTo(b.category.name);
    });

  final heroPhotos = listed
      .map((b) => b.storefrontUrl ?? b.logoUrl)
      .whereType<String>()
      .where((url) => url.isNotEmpty)
      .take(_heroPhotoCap)
      .toList();

  final voiceCandidates = featured.where((b) => b.reviewCount > 0).take(_voiceBusinessCap).toList();
  final voices = <ReviewVoiceItem>[];
  for (final business in voiceCandidates) {
    try {
      final list = await reviews.listForBusiness(business.id);
      ReviewResponse? picked;
      for (final review in list) {
        if (review.body.trim().isNotEmpty) {
          picked = review;
          break;
        }
      }
      picked ??= list.isNotEmpty ? list.first : null;
      if (picked != null) {
        voices.add(ReviewVoiceItem(business: business, review: picked));
      }
    } catch (_) {
      // Skip this voice.
    }
  }

  final loadError = listed.isEmpty && cityNames.isEmpty && loadErrors.isNotEmpty ? loadErrors.join('; ') : null;

  return HomePayload(
    socialProof: socialProof,
    heroPhotos: heroPhotos,
    stats: stats,
    cities: cities,
    categories: categories,
    featured: featured,
    featuredCity: featuredCity,
    voices: voices,
    loadError: loadError,
  );
});
