import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../businesses/business_list_provider.dart';
import '../merchant/merchant_providers.dart';
import '../reviews/review_card.dart';
import '../reviews/review_providers.dart';
import 'platform_series_chart.dart';
import '../../ui/friendly_error.dart';
import '../../ui/widgets.dart';

/// Admin Home (S-031 / M-57–M-59). Replaces the S-027 placeholder.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  PlatformAnalytics? _stats;
  PlatformAnalyticsSeries? _series;
  List<BusinessResponse> _pending = [];
  List<ReviewResponse> _reported = [];
  String? _error;
  bool _loading = true;
  String? _actingId;
  int _seriesDays = 90;

  final _metricsKey = GlobalKey();
  final _trendsKey = GlobalKey();
  final _queueKey = GlobalKey();
  final _reportedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250), alignment: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('dashboardHubScaffold'),
      child: Scaffold(
        key: const Key('adminHomeScreen'),
        appBar: AppBar(title: const Text('Admin')),
        body: MhCanvas(
          child: _loading
              ? const MhSkeleton()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Platform moderation and analytics',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                MhError(error: _error!, onRetry: _load),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                key: const Key('adminOpsNav'),
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text('Users'),
                                    onPressed: () => context.push('/admin/users'),
                                  ),
                                  ActionChip(
                                    label: const Text('Merchants'),
                                    onPressed: () => context.push('/admin/businesses'),
                                  ),
                                  ActionChip(
                                    key: const Key('manageCategoriesButton'),
                                    label: const Text('Categories'),
                                    onPressed: () => context.push('/admin/categories'),
                                  ),
                                  ActionChip(
                                    label: const Text('Reviews'),
                                    onPressed: () => context.push('/admin/reviews'),
                                  ),
                                  KeyedSubtree(
                                    key: const Key('manageSupportTicketsButton'),
                                    child: ActionChip(
                                      key: const Key('opsNavSupport'),
                                      label: const Text('Support'),
                                      onPressed: () => context.push('/admin/support'),
                                    ),
                                  ),
                                  ActionChip(
                                    key: const Key('opsNavShopReports'),
                                    label: const Text('Shop reports'),
                                    onPressed: () => context.push('/admin/business-reports'),
                                  ),
                                  ActionChip(
                                    key: const Key('manageWhatsAppDraftsButton'),
                                    label: const Text('WhatsApp'),
                                    onPressed: () => context.push('/admin/whatsapp'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _JumpChipsDelegate(
                          onMetrics: () => _scrollTo(_metricsKey),
                          onTrends: () => _scrollTo(_trendsKey),
                          onQueue: () => _scrollTo(_queueKey),
                          onReported: () => _scrollTo(_reportedKey),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (_stats != null)
                              KeyedSubtree(
                                key: _metricsKey,
                                child: _AdminMetricList(
                                  stats: _stats!,
                                  onUsers: () => context.push('/admin/users'),
                                  onShops: () => context.push('/admin/businesses'),
                                  onPending: () => _scrollTo(_queueKey),
                                  onReviews: () => context.push('/admin/reviews'),
                                  onReported: () => _scrollTo(_reportedKey),
                                  onTickets: () => context.push('/admin/support'),
                                  onShopReports: () => context.push('/admin/business-reports'),
                                  onProcessing: () => _scrollTo(_queueKey),
                                ),
                              ),
                            if (_series != null) ...[
                              const SizedBox(height: 24),
                              KeyedSubtree(
                                key: _trendsKey,
                                child: KeyedSubtree(
                                  key: const Key('adminTrendsSection'),
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SegmentedButton<int>(
                                      key: const Key('platformSeriesRange'),
                                      showSelectedIcon: false,
                                      segments: const [
                                        ButtonSegment(value: 7, label: Text('7d')),
                                        ButtonSegment(value: 30, label: Text('30d')),
                                        ButtonSegment(value: 90, label: Text('90d')),
                                      ],
                                      selected: {_seriesDays},
                                      onSelectionChanged: (next) {
                                        if (next.isEmpty) return;
                                        _loadSeries(next.first);
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    PlatformSeriesChart(series: _series!),
                                  ],
                                ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            KeyedSubtree(
                              key: _queueKey,
                              child: Text(
                                'Pending & processing',
                                key: const Key('pendingQueueHeading'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (_pending.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('No businesses awaiting review'),
                              )
                            else
                              for (final business in _pending)
                                _PendingQueueRow(
                                  business: business,
                                  acting: _actingId == business.id,
                                  onOpen: () {
                                    final router = GoRouter.maybeOf(context);
                                    if (router == null) return;
                                    router.push('/businesses/${business.slug}');
                                  },
                                  onStartReview: () => _startReview(business.id),
                                  onReturnToPending: () => _returnToPending(business.id),
                                  onApprove: () => _approve(business.id),
                                  onSuspend: () => _suspend(business.id),
                                ),
                            const SizedBox(height: 24),
                            KeyedSubtree(
                              key: _reportedKey,
                              child: Text(
                                'Reported reviews',
                                key: const Key('adminReportedSection'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (_reported.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('No reported reviews'),
                              )
                            else
                              for (final review in _reported) ...[
                                ReviewCard(review: review, showActions: false),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      FilledButton(
                                        onPressed: _actingId == review.id ? null : () => _moderate(review.id, 'hide'),
                                        child: const Text('Hide'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: _actingId == review.id ? null : () => _moderate(review.id, 'restore'),
                                        child: const Text('Restore'),
                                      ),
                                      TextButton(
                                        onPressed: _actingId == review.id ? null : () => _moderate(review.id, 'remove'),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dash = ref.read(dashboardRepositoryProvider);
      final businesses = ref.read(businessRepositoryProvider);
      final reviews = ref.read(reviewRepositoryProvider);
      late final PlatformAnalytics stats;
      late final PlatformAnalyticsSeries series;
      late final List<BusinessResponse> pending;
      late final List<BusinessResponse> processing;
      late final List<ReviewResponse> reported;
      await Future.wait([
        dash.platformAnalytics().then((v) => stats = v),
        dash.platformAnalyticsSeries(days: _seriesDays).then((v) => series = v),
        businesses.listByStatus(BusinessStatus.pending).then((v) => pending = v),
        businesses.listByStatus(BusinessStatus.processing).then((v) => processing = v),
        reviews.listReported().then((v) => reported = v),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _series = series;
        _pending = [...pending, ...processing];
        _reported = reported;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendlyMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _loadSeries(int days) async {
    setState(() => _seriesDays = days);
    try {
      final series = await ref.read(dashboardRepositoryProvider).platformAnalyticsSeries(days: days);
      if (!mounted) return;
      setState(() => _series = series);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(error));
    }
  }

  Future<void> _startReview(String id) async {
    setState(() => _actingId = id);
    try {
      await ref.read(businessRepositoryProvider).startReview(id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _returnToPending(String id) async {
    setState(() => _actingId = id);
    try {
      await ref.read(businessRepositoryProvider).returnToPending(id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _actingId = id);
    try {
      await ref.read(businessRepositoryProvider).approveBusiness(id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _suspend(String id) async {
    setState(() => _actingId = id);
    try {
      await ref.read(businessRepositoryProvider).suspendBusiness(id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _moderate(String id, String action) async {
    setState(() => _actingId = id);
    try {
      await ref.read(reviewRepositoryProvider).moderateReview(reviewId: id, action: action);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }
}

class _JumpChipsDelegate extends SliverPersistentHeaderDelegate {
  _JumpChipsDelegate({
    required this.onMetrics,
    required this.onTrends,
    required this.onQueue,
    required this.onReported,
  });

  final VoidCallback onMetrics;
  final VoidCallback onTrends;
  final VoidCallback onQueue;
  final VoidCallback onReported;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.96),
      child: ListView(
        key: const Key('adminJumpChips'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ActionChip(key: const Key('adminJumpMetrics'), label: const Text('Metrics'), onPressed: onMetrics),
          const SizedBox(width: 8),
          ActionChip(key: const Key('adminJumpTrends'), label: const Text('Trends'), onPressed: onTrends),
          const SizedBox(width: 8),
          ActionChip(key: const Key('adminJumpQueue'), label: const Text('Queue'), onPressed: onQueue),
          const SizedBox(width: 8),
          ActionChip(key: const Key('adminJumpReported'), label: const Text('Reported'), onPressed: onReported),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _JumpChipsDelegate oldDelegate) => false;
}

class _AdminMetricList extends StatelessWidget {
  const _AdminMetricList({
    required this.stats,
    required this.onUsers,
    required this.onShops,
    required this.onPending,
    required this.onReviews,
    required this.onReported,
    required this.onTickets,
    required this.onShopReports,
    required this.onProcessing,
  });

  final PlatformAnalytics stats;
  final VoidCallback onUsers;
  final VoidCallback onShops;
  final VoidCallback onPending;
  final VoidCallback onReviews;
  final VoidCallback onReported;
  final VoidCallback onTickets;
  final VoidCallback onShopReports;
  final VoidCallback onProcessing;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_MetricSpec>>[
      [
        _MetricSpec(
          key: const Key('adminMetricUsers'),
          label: 'Users',
          value: '${stats.totalUsers}',
          accent: MhAccent.sky,
          onTap: onUsers,
        ),
        _MetricSpec(label: 'Shops', value: '${stats.totalBusinesses}', accent: MhAccent.mint, onTap: onShops),
      ],
      [
        _MetricSpec(label: 'Pending', value: '${stats.pendingBusinesses}', accent: MhAccent.amber, onTap: onPending),
        _MetricSpec(label: 'Reviews', value: '${stats.totalReviews}', accent: MhAccent.violet, onTap: onReviews),
      ],
      [
        _MetricSpec(label: 'Reported', value: '${stats.reportedReviews}', accent: MhAccent.coral, onTap: onReported),
        _MetricSpec(
          key: const Key('openSupportTicketsTile'),
          label: 'Tickets',
          value: '${stats.openSupportTickets ?? 0}',
          accent: MhAccent.coral,
          onTap: onTickets,
        ),
      ],
      [
        _MetricSpec(
          key: const Key('repeatShopReportsTile'),
          label: 'Shop reports',
          value: '${stats.repeatShopReports ?? 0}',
          accent: MhAccent.coral,
          onTap: onShopReports,
        ),
        _MetricSpec(
          key: const Key('processingBusinessesTile'),
          label: 'Processing',
          value: '${stats.processingBusinesses ?? 0}',
          accent: MhAccent.amber,
          onTap: onProcessing,
        ),
      ],
    ];

    return KeyedSubtree(
      key: const Key('adminMetricsSection'),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              children: [
                Expanded(child: _MetricRow(spec: rows[i][0])),
                const SizedBox(width: 16),
                Expanded(child: _MetricRow(spec: rows[i][1])),
              ],
            ),
            if (i < rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _MetricSpec {
  const _MetricSpec({
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    this.key,
  });

  final Key? key;
  final String label;
  final String value;
  final MhAccent accent;
  final VoidCallback onTap;
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.spec});

  final _MetricSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: spec.key,
      onTap: spec.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(width: 3, height: 28, color: spec.accent.bold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(spec.value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _PendingQueueRow extends StatelessWidget {
  const _PendingQueueRow({
    required this.business,
    required this.acting,
    required this.onOpen,
    required this.onStartReview,
    required this.onReturnToPending,
    required this.onApprove,
    required this.onSuspend,
  });

  final BusinessResponse business;
  final bool acting;
  final VoidCallback onOpen;
  final VoidCallback onStartReview;
  final VoidCallback onReturnToPending;
  final VoidCallback onApprove;
  final VoidCallback onSuspend;

  static final _compact = ButtonStyle(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: Key('openQueueBusiness-${business.id}'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${business.address}, ${business.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (business.status == BusinessStatus.processing)
                  Text(
                    'Processing',
                    key: const Key('processingQueueBadge'),
                    style: theme.textTheme.bodySmall?.copyWith(color: MhAccent.amber.inkFor(theme.brightness)),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              if (business.status == BusinessStatus.pending)
                Expanded(
                  child: TextButton(
                    key: Key('startReview-${business.id}'),
                    style: _compact,
                    onPressed: acting ? null : onStartReview,
                    child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Start review')),
                  ),
                ),
              if (business.status == BusinessStatus.processing)
                Expanded(
                  child: TextButton(
                    key: Key('returnToPending-${business.id}'),
                    style: _compact,
                    onPressed: acting ? null : onReturnToPending,
                    child: const FittedBox(fit: BoxFit.scaleDown, child: Text('To pending')),
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: FilledButton(
                  key: Key('approveBusiness-${business.id}'),
                  style: _compact,
                  onPressed: acting ? null : onApprove,
                  child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Approve')),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextButton(
                  key: Key('suspendBusiness-${business.id}'),
                  style: _compact,
                  onPressed: acting ? null : onSuspend,
                  child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Suspend')),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
