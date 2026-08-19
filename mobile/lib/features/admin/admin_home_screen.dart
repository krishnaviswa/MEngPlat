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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminHomeScreen'),
      appBar: AppBar(title: const Text('Admin')),
      body: MhCanvas(
        child: _loading
          ? const MhSkeleton()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Platform moderation and analytics', style: Theme.of(context).textTheme.bodyMedium),
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
                      ActionChip(label: const Text('Users'), onPressed: () => context.push('/admin/users')),
                      ActionChip(label: const Text('Merchants'), onPressed: () => context.push('/admin/businesses')),
                      ActionChip(label: const Text('Categories'), onPressed: () => context.push('/admin/categories')),
                      ActionChip(label: const Text('Reviews'), onPressed: () => context.push('/admin/reviews')),
                      ActionChip(
                        key: const Key('opsNavSupport'),
                        label: const Text('Support tickets'),
                        onPressed: () => context.push('/admin/support'),
                      ),
                      ActionChip(
                        key: const Key('opsNavShopReports'),
                        label: const Text('Shop reports'),
                        onPressed: () => context.push('/admin/business-reports'),
                      ),
                      ActionChip(label: const Text('WhatsApp'), onPressed: () => context.push('/admin/whatsapp')),
                    ],
                  ),
                  if (_stats != null) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth = (constraints.maxWidth - 8) / 2;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _AdminStat(
                              width: tileWidth,
                              label: 'Total users',
                              value: '${_stats!.totalUsers}',
                              onTap: () => context.push('/admin/users'),
                            ),
                            _AdminStat(
                              width: tileWidth,
                              label: 'Total businesses',
                              value: '${_stats!.totalBusinesses}',
                              onTap: () => context.push('/admin/businesses'),
                            ),
                            _AdminStat(
                              width: tileWidth,
                              label: 'Pending businesses',
                              value: '${_stats!.pendingBusinesses}',
                            ),
                            _AdminStat(
                              width: tileWidth,
                              label: 'Total reviews',
                              value: '${_stats!.totalReviews}',
                              onTap: () => context.push('/admin/reviews'),
                            ),
                            _AdminStat(
                              width: tileWidth,
                              label: 'Reported reviews',
                              value: '${_stats!.reportedReviews}',
                            ),
                            _AdminStat(
                              key: const Key('openSupportTicketsTile'),
                              width: tileWidth,
                              label: 'Open support tickets',
                              value: '${_stats!.openSupportTickets ?? 0}',
                              onTap: () => context.push('/admin/support'),
                            ),
                            _AdminStat(
                              key: const Key('repeatShopReportsTile'),
                              width: tileWidth,
                              label: 'Repeat shop reports',
                              value: '${_stats!.repeatShopReports ?? 0}',
                              onTap: () => context.push('/admin/business-reports'),
                            ),
                            _AdminStat(
                              key: const Key('processingBusinessesTile'),
                              width: tileWidth,
                              label: 'Processing businesses',
                              value: '${_stats!.processingBusinesses ?? 0}',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  if (_series != null) ...[
                    const SizedBox(height: 24),
                    PlatformSeriesChart(series: _series!),
                  ],
                  const SizedBox(height: 12),
                  TextButton.icon(
                    key: const Key('manageCategoriesButton'),
                    onPressed: () => context.push('/admin/categories'),
                    icon: const Icon(Icons.category_outlined),
                    label: const Text('Manage categories'),
                  ),
                  TextButton.icon(
                    key: const Key('manageSupportTicketsButton'),
                    onPressed: () => context.push('/admin/support'),
                    icon: const Icon(Icons.support_agent_outlined),
                    label: const Text('Support tickets'),
                  ),
                  TextButton.icon(
                    key: const Key('manageShopReportsButton'),
                    onPressed: () => context.push('/admin/business-reports'),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Shop reports'),
                  ),
                  TextButton.icon(
                    key: const Key('manageWhatsAppDraftsButton'),
                    onPressed: () => context.push('/admin/whatsapp'),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp drafts'),
                  ),
                  const SizedBox(height: 24),
                  Text('Pending & processing', key: const Key('pendingQueueHeading'), style: Theme.of(context).textTheme.titleMedium),
                  if (_pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No businesses awaiting review'),
                    )
                  else
                    for (final business in _pending)
                      _PendingQueueCard(
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
                  Text('Reported reviews', style: Theme.of(context).textTheme.titleMedium),
                  if (_reported.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No reported reviews'),
                    )
                  else
                    for (final review in _reported)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReviewCard(review: review, showActions: false),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                FilledButton(
                                  onPressed: _actingId == review.id ? null : () => _moderate(review.id, 'hide'),
                                  child: const Text('Hide'),
                                ),
                                OutlinedButton(
                                  onPressed: _actingId == review.id ? null : () => _moderate(review.id, 'restore'),
                                  child: const Text('Restore'),
                                ),
                                OutlinedButton(
                                  onPressed: _actingId == review.id ? null : () => _moderate(review.id, 'remove'),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                ],
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
        dash.platformAnalyticsSeries().then((v) => series = v),
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

class _PendingQueueCard extends StatelessWidget {
  const _PendingQueueCard({
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: Key('openQueueBusiness-${business.id}'),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (business.status == BusinessStatus.processing)
                        const Chip(
                          key: Key('processingQueueBadge'),
                          label: Text('Processing'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  Text(
                    '${business.address}, ${business.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                if (business.status == BusinessStatus.pending)
                  Expanded(
                    child: OutlinedButton(
                      key: Key('startReview-${business.id}'),
                      style: _compact,
                      onPressed: acting ? null : onStartReview,
                      child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Start review')),
                    ),
                  ),
                if (business.status == BusinessStatus.processing)
                  Expanded(
                    child: OutlinedButton(
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
                  child: OutlinedButton(
                    key: Key('suspendBusiness-${business.id}'),
                    style: _compact,
                    onPressed: acting ? null : onSuspend,
                    child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Suspend')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({required this.label, required this.value, required this.width, this.onTap, super.key});

  final String label;
  final String value;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
    return Material(
      color: _washFor(label),
      borderRadius: BorderRadius.circular(16),
      child: onTap == null ? child : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  static Color _washFor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('ticket') || lower.contains('report')) return const Color(0xFFFFE4E6);
    if (lower.contains('pending') || lower.contains('processing')) return const Color(0xFFFEF3C7);
    if (lower.contains('review')) return const Color(0xFFEDE9FE);
    if (lower.contains('user')) return const Color(0xFFE0F2FE);
    if (lower.contains('business')) return const Color(0xFFD1FAE5);
    return const Color(0xFFF0F9FF);
  }
}
