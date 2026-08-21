import 'dart:convert';
import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:share_plus/share_plus.dart';

import '../../ui/friendly_error.dart';
import '../../ui/nav.dart';
import '../../ui/widgets.dart';
import '../auth/auth_provider.dart';
import '../reviews/review_card.dart';
import '../reviews/review_providers.dart';
import 'ai_insights_panel.dart';
import 'benchmark_card.dart';
import 'featured_boost_panel.dart';
import 'google_reviews_panel.dart';
import 'merchant_providers.dart';
import 'rating_distribution_chart.dart';
import 'review_volume_chart.dart';
import 'sentiment_breakdown.dart';
import 'share_review_link_sheet.dart';
import 'whatsapp_update_panel.dart';

enum MerchantSection { hub, insights, reviews, grow, all }

/// S-060/M-61: `range` values the dashboard's date filter accepts, matching
/// the backend's `range=30|90|all` query param exactly (S-033).
const _rangeOptions = {'30': '30d', '90': '90d', 'all': 'All'};

const _statusLabel = {
  BusinessStatus.pending: 'Awaiting approval',
  BusinessStatus.processing: 'Under review',
  BusinessStatus.approved: 'Active',
  BusinessStatus.rejected: 'Rejected',
  BusinessStatus.suspended: 'Suspended',
};

/// Merchant Home (S-031 / M-50–M-53). Replaces the S-027 placeholder.
class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({this.section = MerchantSection.hub, super.key});

  final MerchantSection section;

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  String? _selectedId;
  DashboardStats? _stats;
  MerchantInsightsResponse? _insights;
  BenchmarkResponse? _benchmark;
  TopicClusterResponse? _topics;
  String? _error;
  bool _refreshingAi = false;
  String _range = 'all';
  bool _exportingCsv = false;
  int _loadGen = 0;
  String? _reviewsRefetchedFor;
  final _reviewsKey = GlobalKey();
  final _sentimentKey = GlobalKey();

  static ButtonStyle get _filled48 => FilledButton.styleFrom(minimumSize: const Size.fromHeight(48));

  bool get _showHub => widget.section == MerchantSection.hub || widget.section == MerchantSection.all;
  bool get _showInsights => widget.section == MerchantSection.insights || widget.section == MerchantSection.all;
  bool get _showReviews => widget.section == MerchantSection.reviews || widget.section == MerchantSection.all;
  bool get _showGrow => widget.section == MerchantSection.grow || widget.section == MerchantSection.all;
  bool get _needsDashboardPayload => _showInsights || _showReviews;

  @override
  Widget build(BuildContext context) {
    final ownedAsync = ref.watch(ownedBusinessesProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      key: const Key('merchantHomeScreen'),
      appBar: AppBar(
        title: Text(switch (widget.section) {
          MerchantSection.insights => 'Insights',
          MerchantSection.reviews => 'Reviews',
          MerchantSection.grow => 'Grow',
          _ => 'Merchant',
        }),
        leading: widget.section == MerchantSection.hub || widget.section == MerchantSection.all
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => popOrGo(context, '/merchant'),
              ),
        actions: [
          TextButton(
            key: const Key('addBusinessButton'),
            onPressed: () => context.push('/merchant/businesses/new'),
            child: const Text('Add business'),
          ),
        ],
      ),
      body: ownedAsync.when(
        loading: () => const MhSkeleton(),
        error: (error, _) => Center(child: MhError(error: error, onRetry: () => ref.invalidate(ownedBusinessesProvider))),
        data: (owned) {
          if (owned.isEmpty) {
            final needsId = user == null ||
                user.nationalIdType == null ||
                (user.nationalIdNumber == null || user.nationalIdNumber!.trim().isEmpty);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MhEmpty(
                      key: const Key('merchantEmptyState'),
                      title: 'No business yet',
                      body: needsId
                          ? 'Save a national ID on Profile, then list your shop. Admin approval comes next.'
                          : 'Register your shop or service to see reviews, stats, and AI insights here.',
                      action: FilledButton(
                        key: const Key('createBusinessCta'),
                        onPressed: () => context.push(needsId ? '/account/profile' : '/merchant/businesses/new'),
                        child: Text(needsId ? 'Add national ID' : 'Create your business'),
                      ),
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
              if (_needsDashboardPayload) _loadDashboard(business.id);
            });
          } else if (_needsDashboardPayload && _stats == null && _error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadDashboard(business.id);
            });
          }
          if (_showReviews) _refetchReviews(business.id);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ownedBusinessesProvider);
              if (_needsDashboardPayload) await _loadDashboard(business.id);
            },
            child: MhCanvas(
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
                          child: Text(
                            item.status == BusinessStatus.pending
                                ? '${item.name} (pending)'
                                : item.status == BusinessStatus.processing
                                    ? '${item.name} (processing)'
                                    : item.name,
                          ),
                        ),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      setState(() {
                        _selectedId = id;
                        _stats = null;
                        _insights = null;
                        _benchmark = null;
                        _topics = null;
                        _error = null;
                        _reviewsRefetchedFor = null;
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
                if (business.status == BusinessStatus.processing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      key: Key('processingUnderReviewBanner'),
                      'Your business is currently being reviewed by an admin. You can update details anytime; public discovery starts after approval.',
                    ),
                  ),
                if (_error != null) MhError(error: _error!, onRetry: () => _loadDashboard(business.id)),
                if (_showHub)
                KeyedSubtree(
                  key: const Key('dashboardHubScaffold'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                Row(
                  children: [
                    Expanded(
                      child: MhStatTile(
                        key: const Key('totalReviewsTile'),
                        label: 'Total reviews',
                        value: '${_stats?.totalReviews ?? business.reviewCount}',
                        accent: MhAccent.sky,
                        onTap: () => _openSection(MerchantSection.reviews, _reviewsKey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MhStatTile(
                        key: const Key('averageRatingTile'),
                        label: 'Average rating',
                        value: (_stats?.averageRating ?? business.averageRating).toDouble().toStringAsFixed(1),
                        accent: MhAccent.amber,
                        onTap: () => _openSection(MerchantSection.insights, _sentimentKey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MhStatTile(
                        key: const Key('statusTile'),
                        label: 'Status',
                        value: _statusLabel[business.status] ?? business.status.name,
                        accent: MhAccent.mint,
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
                MhJobTile(
                  key: const Key('merchantInsightsJob'),
                  icon: Icons.insights_outlined,
                  title: 'Insights',
                  subtitle: 'Charts, range, AI suggestions',
                  accent: MhAccent.violet,
                  onTap: () => _openSection(MerchantSection.insights, _sentimentKey),
                ),
                const SizedBox(height: 8),
                MhJobTile(
                  key: const Key('merchantReviewsJob'),
                  icon: Icons.rate_review_outlined,
                  title: 'Reviews',
                  subtitle: 'Replies and CSV export',
                  accent: MhAccent.coral,
                  onTap: () => _openSection(MerchantSection.reviews, _reviewsKey),
                ),
                const SizedBox(height: 8),
                MhJobTile(
                  key: const Key('merchantGrowJob'),
                  icon: Icons.rocket_launch_outlined,
                  title: 'Grow',
                  subtitle: 'Featured, Google, WhatsApp, QR',
                  accent: MhAccent.amber,
                  onTap: () => _openSection(MerchantSection.grow, _reviewsKey),
                ),
                const SizedBox(height: 16),
                    ],
                  ),
                ),
                if (_showInsights) ...[
                SegmentedButton<String>(
                  key: const Key('dashboardRangeSelector'),
                  showSelectedIcon: false,
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
                _InsightsHero(
                  rating: (_stats?.averageRating ?? business.averageRating).toDouble().toStringAsFixed(1),
                  replyRate: _stats?.replyRate,
                  replyRatePrevious: _stats?.replyRatePrevious,
                  reviewCountInRange: _stats?.reviewCountInRange ?? 0,
                  reviewCountPrevious: _stats?.reviewCountPrevious,
                  range: _range,
                  onOpenReviews: () => _scrollTo(_reviewsKey),
                ),
                const SizedBox(height: 16),
                ReviewVolumeChart(volumeByMonth: _stats?.reviewVolumeByMonth ?? BuiltList<JsonObject>()),
                const SizedBox(height: 16),
                RatingDistributionChart(counts: Map<String, int>.from(_stats?.ratingDistribution.toMap() ?? {})),
                ],
                if (_showGrow) ...[
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
                if (business.status == BusinessStatus.approved) ...[
                  const SizedBox(height: 16),
                  FeaturedBoostPanel(business: business),
                  const SizedBox(height: 16),
                  GoogleReviewsPanel(business: business),
                  const SizedBox(height: 16),
                  WhatsAppUpdatePanel(business: business),
                ],
                ],
                if (_showInsights) ...[
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: _sentimentKey,
                  child: SentimentBreakdown(counts: Map<String, int>.from(_stats?.sentimentBreakdown.toMap() ?? {})),
                ),
                if (_benchmark != null) ...[
                  const SizedBox(height: 16),
                  BenchmarkCard(benchmark: _benchmark!),
                ],
                const SizedBox(height: 16),
                Text(
                  'Refresh AI summary when you want an updated suggestion.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('refreshAiButton'),
                    style: _filled48,
                    onPressed: _refreshingAi ? null : () => _refreshAi(business.id),
                    child: Text(_refreshingAi ? 'Refreshing...' : 'Refresh AI insights'),
                  ),
                ),
                const SizedBox(height: 8),
                if (_insights != null) AiInsightsPanel(insights: _insights!, topics: _topics),
                ],
                if (_showReviews) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('exportCsvButton'),
                    style: _filled48,
                    onPressed: _exportingCsv ? null : () => _exportCsv(business.id),
                    child: Text(_exportingCsv ? 'Exporting...' : 'Export CSV'),
                  ),
                ),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _reviewsKey,
                  child: _MerchantReviewsList(
                    business: business,
                    reviewCount: _stats?.totalReviews ?? business.reviewCount,
                    onReply: _postReply,
                  ),
                ),
                ],
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadDashboard(String businessId) async {
    final gen = ++_loadGen;
    setState(() => _error = null);
    final repo = ref.read(dashboardRepositoryProvider);

    if (_needsDashboardPayload) {
      try {
        final stats = await repo.merchantStats(businessId, range: _range);
        if (!mounted || gen != _loadGen) return;
        setState(() => _stats = stats);
      } catch (error) {
        if (!mounted || gen != _loadGen) return;
        setState(() => _error = friendlyMessage(error));
        return;
      }
    }

    if (!_showInsights) return;

    await Future.wait([
      () async {
        try {
          final insights = await repo.insights(businessId);
          if (!mounted || gen != _loadGen) return;
          setState(() => _insights = insights);
        } catch (_) {}
      }(),
      () async {
        try {
          final benchmark = await repo.benchmark(businessId);
          if (!mounted || gen != _loadGen) return;
          setState(() => _benchmark = benchmark);
        } catch (_) {}
      }(),
      () async {
        try {
          final topics = await repo.topicClusters(businessId);
          if (!mounted || gen != _loadGen) return;
          setState(() => _topics = topics);
        } catch (_) {}
      }(),
    ]);
  }

  Future<void> _refreshAi(String businessId) async {
    setState(() => _refreshingAi = true);
    try {
      final insights = await ref.read(dashboardRepositoryProvider).refreshInsights(businessId);
      if (!mounted) return;
      setState(() => _insights = insights);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(error))));
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
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  void _refetchReviews(String businessId) {
    if (_reviewsRefetchedFor == businessId) return;
    _reviewsRefetchedFor = businessId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(reviewsControllerProvider(businessId));
    });
  }

  Future<void> _postReply(String reviewId, String body) async {
    final reply = await ref.read(reviewRepositoryProvider).replyToReview(reviewId: reviewId, body: body);
    if (!mounted) return;
    final businessId = _selectedId;
    if (businessId != null) {
      ref.read(reviewsControllerProvider(businessId).notifier).applyReply(reviewId, reply);
    }
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

  void _openSection(MerchantSection section, GlobalKey key) {
    if (widget.section == MerchantSection.all) {
      _scrollTo(key);
      return;
    }
    if (GoRouter.maybeOf(context) == null) {
      _scrollTo(key);
      return;
    }
    switch (section) {
      case MerchantSection.insights:
        context.push('/merchant/insights');
      case MerchantSection.reviews:
        context.push('/merchant/reviews');
      case MerchantSection.grow:
        context.push('/merchant/grow');
      case MerchantSection.hub:
      case MerchantSection.all:
        _scrollTo(key);
    }
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250), alignment: 0.1);
  }
}

class _InsightsHero extends StatelessWidget {
  const _InsightsHero({
    required this.rating,
    required this.replyRate,
    required this.replyRatePrevious,
    required this.reviewCountInRange,
    required this.reviewCountPrevious,
    required this.range,
    required this.onOpenReviews,
  });

  final String rating;
  final num? replyRate;
  final num? replyRatePrevious;
  final int reviewCountInRange;
  final num? reviewCountPrevious;
  final String range;
  final VoidCallback onOpenReviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replyEmpty = replyRate == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rating, style: theme.textTheme.headlineMedium),
        Text('Average rating', style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        InkWell(
          key: const Key('replyRateTile'),
          onTap: onOpenReviews,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Reply rate', style: theme.textTheme.bodySmall)),
                  Text(
                    replyEmpty ? '—' : '${(replyRate! * 100).round()}%',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (!replyEmpty) ...[
                    const SizedBox(width: 6),
                    _TrendDelta(current: replyRate, previous: replyRatePrevious, range: range),
                  ],
                ],
              ),
              if (replyEmpty)
                Text('No reviews in this range', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('reviewCountInRangeTile'),
          onTap: onOpenReviews,
          child: Row(
            children: [
              Expanded(child: Text('Reviews in this range', style: theme.textTheme.bodySmall)),
              Text('$reviewCountInRange', style: theme.textTheme.titleMedium),
              const SizedBox(width: 6),
              _TrendDelta(current: reviewCountInRange, previous: reviewCountPrevious, range: range),
            ],
          ),
        ),
      ],
    );
  }
}

class _MerchantReviewsList extends ConsumerWidget {
  const _MerchantReviewsList({
    required this.business,
    required this.reviewCount,
    required this.onReply,
  });

  final BusinessResponse business;
  final int reviewCount;
  final Future<void> Function(String reviewId, String body) onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsControllerProvider(business.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        reviewsAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const MhSkeleton(),
          error: (error, _) => MhError(
            error: error,
            onRetry: () => ref.invalidate(reviewsControllerProvider(business.id)),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Text(reviewCount > 0 ? 'Held for review' : 'No reviews yet.');
            }
            return Column(
              children: [
                for (final review in reviews)
                  ReviewCard(
                    review: review,
                    showActions: false,
                    canReply: true,
                    onReply: (body) => onReply(review.id, body),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TrendDelta extends StatelessWidget {
  const _TrendDelta({required this.current, required this.previous, required this.range});

  final num? current;
  final num? previous;
  final String range;

  @override
  Widget build(BuildContext context) {
    if (range == 'all') return const SizedBox.shrink();

    if (previous == null) {
      return Text(
        '—',
        key: const Key('trendDeltaUndefined'),
        semanticsLabel: 'not enough data for previous period',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    // previous == 0 (a real zero, not null) is division-by-zero -- treat
    // identically to the undefined case above, never a fabricated large
    // percentage (S-063 Risks: not directly forced by any AC's wording).
    final prev = previous!;
    final cur = current ?? 0;
    if (prev == 0) {
      return Text(
        '—',
        key: const Key('trendDeltaUndefined'),
        semanticsLabel: 'not enough data for previous period',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final delta = (cur - prev) / prev;
    final up = delta >= 0;
    return Row(
      key: const Key('trendDeltaValue'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: up ? Colors.green : Theme.of(context).colorScheme.error,
        ),
        Text(
          '${(delta.abs() * 100).round()}%',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: up ? Colors.green : Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}
