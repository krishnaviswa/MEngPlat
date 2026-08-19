import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/widgets.dart';
import '../auth/auth_provider.dart';
import '../favorites/favorite_toggle_button.dart';
import '../reviews/rating_stars.dart';
import '../reviews/review_card.dart';
import '../reviews/review_filter_sheet.dart';
import '../reviews/review_form_sheet.dart';
import '../reviews/review_providers.dart';
import 'business_hours.dart';
import 'business_list_provider.dart';
import 'external_reviews_section.dart';
import 'maps_config.dart';
import 'osm_map_view.dart';
import 'photo_gallery.dart';
import 'report_shop_button.dart';

/// Public business profile (ADR-003): header, contact/hours/photos/map/AI
/// overview (S-028), plus reviews + "Add review" (S-023).
class BusinessDetailScreen extends ConsumerWidget {
  const BusinessDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Business')),
      body: businessAsync.when(
        loading: () => const MhSkeleton(),
        error: (error, _) => Center(
          child: MhError(error: error, onRetry: () => ref.invalidate(businessDetailProvider(slug))),
        ),
        data: (business) => _BusinessDetailBody(business: business),
      ),
    );
  }
}

class _BusinessDetailBody extends ConsumerStatefulWidget {
  const _BusinessDetailBody({required this.business});

  final BusinessResponse business;

  @override
  ConsumerState<_BusinessDetailBody> createState() => _BusinessDetailBodyState();
}

class _BusinessDetailBodyState extends ConsumerState<_BusinessDetailBody> {
  ReviewListFilter _filter = const ReviewListFilter();

  BusinessResponse get business => widget.business;

  List<ReviewResponse> _visibleReviews(List<ReviewResponse> reviews) {
    final filtered = _filter.minRating > 0
        ? reviews.where((r) => r.rating >= _filter.minRating).toList()
        : reviews;
    final sorted = List<ReviewResponse>.of(filtered);
    sorted.sort((a, b) => switch (_filter.sortBy) {
          ReviewSortOption.newest => b.createdAt.compareTo(a.createdAt),
          ReviewSortOption.oldest => a.createdAt.compareTo(b.createdAt),
          ReviewSortOption.highest => b.rating.compareTo(a.rating),
          ReviewSortOption.lowest => a.rating.compareTo(b.rating),
        });
    return sorted;
  }

  Future<void> _openFilters() async {
    final result = await showReviewFilterSheet(context: context, initial: _filter);
    if (result == null || !mounted) return;
    setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(reviewsControllerProvider(business.id));
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isLoggedIn = user != null;

    // Wait for eligibility data before showing "Add review" so AC10/AC12
    // don't briefly flash the button for an already-reviewed or own business.
    final reviewsReady = !reviewsAsync.isLoading;
    final reviews = reviewsAsync.valueOrNull ?? const <ReviewResponse>[];
    final alreadyReviewed = hasAlreadyReviewed(reviews, user?.id);
    final myBusinessIdsAsync = ref.watch(myBusinessIdsProvider);
    final ownershipReady = user?.role != UserRole.merchant || !myBusinessIdsAsync.isLoading;
    final myBusinessIds = myBusinessIdsAsync.valueOrNull ?? const <String>{};
    final isOwnBusiness = user?.role == UserRole.merchant && myBusinessIds.contains(business.id);
    // AC13: the action is still shown to a logged-out guest -- only the tap
    // target changes (push /login instead of opening the form).
    final showAddReview = reviewsReady && ownershipReady && !alreadyReviewed && !isOwnBusiness;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(reviewsControllerProvider(business.id).future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(business.name, style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      FavoriteToggleButton(businessId: business.id),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_placeLine(business)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingStars(rating: business.averageRating),
                      const SizedBox(width: 4),
                      Text(business.averageRating.toStringAsFixed(1)),
                      const SizedBox(width: 8),
                      Text('${business.reviewCount} reviews', style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      if (reviews.isNotEmpty)
                        IconButton(
                          key: const Key('reviewFiltersButton'),
                          onPressed: _openFilters,
                          tooltip: 'Sort & filter reviews',
                          icon: Badge(
                            isLabelVisible: _filter.hasActiveFilter,
                            smallSize: 8,
                            child: const Icon(Icons.tune),
                          ),
                        ),
                    ],
                  ),
                  if (business.description != null && business.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(business.description!, key: const Key('businessDescription')),
                  ],
                  if (business.aiMerchantSummary != null && business.aiMerchantSummary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AiOverview(summary: business.aiMerchantSummary!),
                  ],
                  _ContactBlock(business: business),
                  _CategoryChips(categories: business.categories?.toList() ?? const []),
                  _HoursBlock(business: business),
                  _GalleryBlock(business: business),
                  _DetailMap(business: business),
                  _ExternalReviewsBlock(businessId: business.id),
                  const SizedBox(height: 12),
                  ReportShopButton(businessId: business.id, isOwnBusiness: isOwnBusiness),
                  if (showAddReview) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('addReviewButton'),
                      onPressed: () => _onAddReview(context, isLoggedIn),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Add review'),
                    ),
                  ],
                  const Divider(height: 32),
                ],
              ),
            ),
          ),
          reviewsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error.toString()),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(reviewsControllerProvider(business.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (reviews) {
              final reviewsController = ref.read(reviewsControllerProvider(business.id).notifier);
              if (reviews.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No reviews yet — be the first to review')),
                );
              }
              final visible = _visibleReviews(reviews);
              if (visible.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Container(
                      key: const Key('reviewFiltersEmptyState'),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No reviews match these filters'),
                          const SizedBox(height: 8),
                          TextButton(
                            key: const Key('clearReviewFiltersButton'),
                            onPressed: () => setState(() => _filter = ReviewListFilter(sortBy: _filter.sortBy)),
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    ReviewCard(
                      review: visible[index],
                      reported: reviewsController.reportedIds.contains(visible[index].id),
                      onLike: isLoggedIn
                          ? () async {
                              try {
                                await reviewsController.likeReview(visible[index].id);
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
                                }
                              }
                            }
                          : () => context.push('/login'),
                      onReport: isLoggedIn
                          ? (reason) => reviewsController.reportReview(
                                reviewId: visible[index].id,
                                reason: reason,
                              )
                          : null,
                      onRequireLogin: isLoggedIn ? null : () => context.push('/login'),
                    ),
                    if (index != visible.length - 1) const Divider(height: 1),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onAddReview(BuildContext context, bool isLoggedIn) {
    if (!isLoggedIn) {
      context.push('/login');
      return;
    }
    ReviewFormSheet.show(context, businessId: business.id);
  }
}

String _placeLine(BusinessResponse business) {
  return [
    business.address,
    business.city,
    business.state,
    business.postalCode,
  ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
}

class _ExternalReviewsBlock extends ConsumerWidget {
  const _ExternalReviewsBlock({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(externalReviewsProvider(businessId));
    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reviews) => ExternalReviewsSection(reviews: reviews),
    );
  }
}

class _AiOverview extends StatelessWidget {
  const _AiOverview({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('aiOverviewSuggestion'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'AI overview (suggestion): ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: summary, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.business});

  final BusinessResponse business;

  @override
  Widget build(BuildContext context) {
    final phone = business.phone?.trim();
    final website = business.website?.trim();
    final address = business.address.trim();
    if ((phone == null || phone.isEmpty) && (website == null || website.isEmpty) && address.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty)
            Text(address, key: const Key('businessAddress')),
          if (phone != null && phone.isNotEmpty)
            TextButton.icon(
              key: const Key('businessPhone'),
              onPressed: () => launchUrl(Uri.parse('tel:$phone')),
              icon: const Icon(Icons.phone, size: 18),
              label: Text(phone),
            ),
          if (website != null && website.isNotEmpty)
            TextButton.icon(
              key: const Key('businessWebsite'),
              onPressed: () {
                final href = website.startsWith('http') ? website : 'https://$website';
                launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.language, size: 18),
              label: Text(website),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.categories});

  final List<CategoryResponse> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        key: const Key('categoryChips'),
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final category in categories)
            ActionChip(
              label: Text(category.name),
              onPressed: () => context.push('/businesses?category=${category.slug}'),
            ),
        ],
      ),
    );
  }
}

class _HoursBlock extends StatelessWidget {
  const _HoursBlock({required this.business});

  final BusinessResponse business;

  @override
  Widget build(BuildContext context) {
    final entries = businessHoursEntries(business.businessHours);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        key: const Key('hoursBlock'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hours', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          if (entries.isEmpty)
            const Text('Hours not listed')
          else
            for (final entry in entries) Text('${entry.key}: ${entry.value}'),
        ],
      ),
    );
  }
}

class _GalleryBlock extends ConsumerWidget {
  const _GalleryBlock({required this.business});

  final BusinessResponse business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(businessPhotosProvider(business.id));
    return photosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 12),
        child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) {
        final fallback = PhotoGallery.urlsFor(business, const []);
        if (fallback.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FallbackPhotoStrip(urls: fallback),
        );
      },
      data: (photos) {
        if (photos.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: PhotoGallery(photos: photos),
          );
        }
        final fallback = PhotoGallery.urlsFor(business, const []);
        if (fallback.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FallbackPhotoStrip(urls: fallback),
        );
      },
    );
  }
}

class _DetailMap extends ConsumerWidget {
  const _DetailMap({required this.business});

  final BusinessResponse business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (business.latitude == null || business.longitude == null) {
      return const SizedBox.shrink();
    }
    final config = ref.watch(mapsConfigProvider).valueOrNull ?? MapsConfig.fallback;
    final point = LatLng(business.latitude!.toDouble(), business.longitude!.toDouble());
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          OsmMapView(
            mapKey: const Key('detailMapPin'),
            markers: [
              MapMarkerTap(point: point, slug: business.slug, name: business.name),
            ],
            config: config,
            center: point,
            zoom: 15,
            height: 200,
          ),
        ],
      ),
    );
  }
}
