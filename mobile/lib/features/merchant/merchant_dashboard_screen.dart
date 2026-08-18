import 'dart:convert';
import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:share_plus/share_plus.dart';

import '../reviews/review_card.dart';
import '../reviews/review_providers.dart';
import 'ai_insights_panel.dart';
import 'merchant_providers.dart';
import 'rating_distribution_chart.dart';
import 'review_volume_chart.dart';
import 'sentiment_breakdown.dart';
import 'share_review_link_sheet.dart';

/// S-060/M-61: `range` values the dashboard's date filter accepts, matching
/// the backend's `range=30|90|all` query param exactly (S-033).
const _rangeOptions = {'30': 'Last 30 days', '90': 'Last 90 days', 'all': 'All time'};

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
  String _range = 'all';
  bool _exportingCsv = false;
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
                const SizedBox(height: 16),
                // S-060/M-61 AC 3: date-range filter -- changing it is a live
                // refetch (not a client-side filter of the all-time payload).
                SegmentedButton<String>(
                  key: const Key('dashboardRangeSelector'),
                  segments: [
                    for (final entry in _rangeOptions.entries) ButtonSegment(value: entry.key, label: Text(entry.value)),
                  ],
                  selected: {_range},
                  onSelectionChanged: (selected) {
                    final range = selected.first;
                    setState(() => _range = range);
                    _loadDashboard(business.id);
                  },
                ),
                const SizedBox(height: 16),
                ReviewVolumeChart(volumeByMonth: _stats?.reviewVolumeByMonth ?? BuiltList<JsonObject>()),
                const SizedBox(height: 16),
                RatingDistributionChart(counts: Map<String, int>.from(_stats?.ratingDistribution.toMap() ?? {})),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        key: const Key('replyRateTile'),
                        label: 'Reply rate',
                        value: _stats?.replyRate == null
                            ? 'No reviews in this range'
                            : '${(_stats!.replyRate! * 100).round()}%',
                        onTap: () => _scrollTo(_reviewsKey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('exportCsvButton'),
                        onPressed: _exportingCsv ? null : () => _exportCsv(business.id),
                        child: Text(_exportingCsv ? 'Exporting...' : 'Export CSV'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Wrap, not Row: two text buttons can overflow a narrow-phone
                // width (found via S-060's widget tests) -- wrapping to a
                // second line beats a RenderFlex overflow.
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/merchant/businesses/${business.id}/edit'),
                      child: const Text('Edit business'),
                    ),
                    if (business.status == BusinessStatus.approved)
                      TextButton(
                        key: const Key('shareReviewLinkButton'),
                        onPressed: () => ShareReviewLinkSheet.show(
                          context,
                          businessName: business.name,
                          slug: business.slug,
                        ),
                        child: const Text('Share review link'),
                      ),
                  ],
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
      final stats = await repo.merchantStats(businessId, range: _range);
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

  /// S-060/M-61 AC 6: fetches this business's reviews as CSV and hands it to
  /// the native share sheet -- mobile's equivalent of web's browser
  /// download. Own-business-only is enforced by the existing, unmodified
  /// backend ownership check; a 403 (or any failure) surfaces through the
  /// same `_error` pattern used elsewhere on this screen, never a silent
  /// empty file.
  Future<void> _exportCsv(String businessId) async {
    setState(() => _exportingCsv = true);
    try {
      final csv = await ref.read(dashboardRepositoryProvider).reviewsCsv(businessId, range: _range);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final fileName = 'reviews-$businessId-$_range.csv';
      await SharePlus.instance.share(
        ShareParams(
          // `XFile.fromData`'s own `name` parameter is documented as ignored
          // on every non-web platform (cross_file's io implementation derives
          // `name` from `path`, which is empty here) -- `fileNameOverrides`
          // is `share_plus`'s own documented workaround for exactly this,
          // confirmed by widget-test assertion on the shared file's name.
          files: [XFile.fromData(bytes, name: fileName, mimeType: 'text/csv')],
          fileNameOverrides: [fileName],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
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
