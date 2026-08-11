import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';
import '../favorites/favorite_toggle_button.dart';
import '../reviews/review_card.dart';
import '../reviews/review_form_sheet.dart';
import '../reviews/review_providers.dart';
import 'business_list_provider.dart';

/// Minimal business detail shell: header (name, average rating, review
/// count) + reviews list + "Add review" action. A **public** route (see
/// ADR-003) -- reachable while logged out (S-023 AC13). Full profile parity
/// (hours, photo gallery, map, AI merchant summary) is a separate future
/// slice.
class BusinessDetailScreen extends ConsumerWidget {
  const BusinessDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Business')),
      body: businessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(businessDetailProvider(slug)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (business) => _BusinessDetailBody(business: business),
      ),
    );
  }
}

class _BusinessDetailBody extends ConsumerWidget {
  const _BusinessDetailBody({required this.business});

  final BusinessResponse business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      // S-024 AC1: favoriting also available from the detail
                      // screen, not just the list row.
                      FavoriteToggleButton(businessId: business.id),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text([business.city, business.state].whereType<String>().join(', ')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(business.averageRating.toStringAsFixed(1)),
                      const SizedBox(width: 8),
                      Text('${business.reviewCount} reviews', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
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
              if (reviews.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No reviews yet — be the first to review')),
                );
              }
              return SliverList.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    ReviewCard(review: reviews[index]),
                    if (index != reviews.length - 1) const Divider(height: 1),
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
