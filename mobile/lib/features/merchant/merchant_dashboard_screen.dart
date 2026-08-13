import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../reviews/review_card.dart';
import '../reviews/review_providers.dart';
import 'ai_insights_panel.dart';
import 'merchant_providers.dart';
import 'sentiment_breakdown.dart';

const _statusLabel = {
  BusinessStatus.pending: 'Awaiting approval',
  BusinessStatus.approved: 'Active',
  BusinessStatus.rejected: 'Rejected',
  BusinessStatus.suspended: 'Suspended',
};

/// Merchant Home (S-031 / M-50–M-53). Replaces the S-027 placeholder.
class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  String? _selectedId;
  DashboardStats? _stats;
  MerchantInsightsResponse? _insights;
  String? _error;
  bool _refreshingAi = false;
  final _reviewsKey = GlobalKey();
  final _sentimentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final ownedAsync = ref.watch(ownedBusinessesProvider);

    return Scaffold(
      key: const Key('merchantHomeScreen'),
      appBar: AppBar(
        title: const Text('Merchant'),
        actions: [
          TextButton(
            key: const Key('addBusinessButton'),
            onPressed: () => context.push('/merchant/businesses/new'),
            child: const Text('Add business'),
          ),
        ],
      ),
      body: ownedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorRetry(message: '$error', onRetry: () => ref.invalidate(ownedBusinessesProvider)),
        data: (owned) {
          if (owned.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No business yet', key: Key('merchantEmptyState')),
                    const SizedBox(height: 8),
                    const Text('Register your shop or service to see reviews, stats, and AI insights here.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('createBusinessCta'),
                      onPressed: () => context.push('/merchant/businesses/new'),
                      child: const Text('Create your business'),
                    ),
                  ],
                ),
              ),
            );
          }

          final selectedId = _selectedId ?? owned.first.id;
          final business = owned.firstWhere((b) => b.id == selectedId, orElse: () => owned.first);
          if (_selectedId != business.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedId = business.id);
              _loadDashboard(business.id);
            });
          } else if (_stats == null && _error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadDashboard(business.id);
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ownedBusinessesProvider);
              await _loadDashboard(business.id);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (owned.length > 1) ...[
                  const Text('Your businesses'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    key: const Key('merchantBusinessSelector'),
                    isExpanded: true,
                    value: business.id,
                    items: [
                      for (final item in owned)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.status == BusinessStatus.pending ? '${item.name} (pending)' : item.name),
                        ),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      setState(() {
                        _selectedId = id;
                        _stats = null;
                        _insights = null;
                        _error = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (business.status == BusinessStatus.pending)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Your business is awaiting admin approval. You can update details anytime; public discovery starts after approval.',
                    ),
                  ),
                if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        key: const Key('totalReviewsTile'),
                        label: 'Total reviews',
                        value: '${_stats?.totalReviews ?? 0}',
                        onTap: () => _scrollTo(_reviewsKey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        key: const Key('averageRatingTile'),
                        label: 'Average rating',
                        value: (_stats?.averageRating ?? 0).toDouble().toStringAsFixed(1),
                        onTap: () => _scrollTo(_sentimentKey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        key: const Key('statusTile'),
                        label: 'Status',
                        value: _statusLabel[business.status] ?? business.status.name,
                        onTap: () {
                          if (business.status == BusinessStatus.approved) {
                            context.push('/businesses/${business.slug}');
                          } else {
                            context.push('/merchant/businesses/${business.id}/edit');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.push('/merchant/businesses/${business.id}/edit'),
                    child: const Text('Edit business'),
                  ),
                ),
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: _sentimentKey,
                  child: SentimentBreakdown(counts: Map<String, int>.from(_stats?.sentimentBreakdown.toMap() ?? {})),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('Refresh AI summary when you want an updated suggestion.')),
                    OutlinedButton(
                      key: const Key('refreshAiButton'),
                      onPressed: _refreshingAi ? null : () => _refreshAi(business.id),
                      child: Text(_refreshingAi ? 'Refreshing...' : 'Refresh AI insights'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_insights != null) AiInsightsPanel(insights: _insights!),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _reviewsKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent reviews', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if ((_stats?.recentReviews.isEmpty ?? true))
                        const Text('No reviews yet.')
                      else
                        for (final review in _stats!.recentReviews)
                          ReviewCard(
                            review: review,
                            showActions: false,
                            canReply: true,
                            onReply: (body) => _postReply(review.id, body),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadDashboard(String businessId) async {
    setState(() => _error = null);
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final stats = await repo.merchantStats(businessId);
      MerchantInsightsResponse? insights;
      try {
        insights = await repo.insights(businessId);
      } catch (_) {
        insights = null;
      }
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _insights = insights;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _refreshAi(String businessId) async {
    setState(() => _refreshingAi = true);
    try {
      final insights = await ref.read(dashboardRepositoryProvider).refreshInsights(businessId);
      if (!mounted) return;
      setState(() => _insights = insights);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _refreshingAi = false);
    }
  }

  Future<void> _postReply(String reviewId, String body) async {
    final reply = await ref.read(reviewRepositoryProvider).replyToReview(reviewId: reviewId, body: body);
    if (!mounted) return;
    final stats = _stats;
    if (stats == null) return;
    setState(() {
      _stats = stats.rebuild((b) {
        b.recentReviews.replace([
          for (final review in stats.recentReviews)
            if (review.id == reviewId) review.rebuild((r) => r.reply.replace(reply)) else review,
        ]);
      });
    });
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250), alignment: 0.1);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.onTap, super.key});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
