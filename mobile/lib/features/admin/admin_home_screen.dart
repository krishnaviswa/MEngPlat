import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../businesses/business_list_provider.dart';
import '../merchant/merchant_providers.dart';
import '../reviews/review_card.dart';
import '../reviews/review_providers.dart';
import 'platform_series_chart.dart';

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Platform moderation and analytics', style: Theme.of(context).textTheme.bodyMedium),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    OutlinedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                  if (_stats != null) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AdminStat(
                          label: 'Total users',
                          value: '${_stats!.totalUsers}',
                          onTap: () => context.push('/admin/users'),
                        ),
                        _AdminStat(
                          label: 'Total businesses',
                          value: '${_stats!.totalBusinesses}',
                          onTap: () => context.push('/admin/businesses'),
                        ),
                        _AdminStat(label: 'Pending businesses', value: '${_stats!.pendingBusinesses}'),
                        _AdminStat(
                          label: 'Total reviews',
                          value: '${_stats!.totalReviews}',
                          onTap: () => context.push('/admin/reviews'),
                        ),
                        _AdminStat(label: 'Reported reviews', value: '${_stats!.reportedReviews}'),
                      ],
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
                  const SizedBox(height: 24),
                  Text('Pending businesses', style: Theme.of(context).textTheme.titleMedium),
                  if (_pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No pending businesses'),
                    )
                  else
                    for (final business in _pending)
                      Card(
                        child: ListTile(
                          title: Text(business.name),
                          subtitle: Text('${business.address}, ${business.city}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                key: Key('approveBusiness-${business.id}'),
                                onPressed: _actingId == business.id ? null : () => _approve(business.id),
                                child: const Text('Approve'),
                              ),
                              OutlinedButton(
                                key: Key('suspendBusiness-${business.id}'),
                                onPressed: _actingId == business.id ? null : () => _suspend(business.id),
                                child: const Text('Suspend'),
                              ),
                            ],
                          ),
                        ),
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
      final stats = await dash.platformAnalytics();
      final series = await dash.platformAnalyticsSeries();
      final pending = await businesses.listByStatus(BusinessStatus.pending);
      final reported = await reviews.listReported();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _series = series;
        _pending = pending;
        _reported = reported;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _actingId = id);
    try {
      await ref.read(businessRepositoryProvider).approveBusiness(id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
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
      setState(() => _error = error.toString());
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
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: 160,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: onTap == null ? child : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: child),
    );
  }
}
