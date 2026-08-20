import 'package:flutter/material.dart';

import 'widgets.dart';

/// Shared merchant/admin hub chrome (S-113). Home stays `/home`; this is the
/// Shop/Hub tab only.
class DashboardHubScaffold extends StatelessWidget {
  const DashboardHubScaffold({
    required this.title,
    required this.stats,
    required this.jobs,
    this.leading,
    this.actions,
    this.body,
    super.key,
  });

  final String title;
  final List<Widget> stats;
  final List<Widget> jobs;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dashboardHubScaffold'),
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      body: MhCanvas(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: stats),
            const SizedBox(height: 16),
            ...jobs,
            if (body != null) ...[const SizedBox(height: 16), body!],
          ],
        ),
      ),
    );
  }
}

class DashboardSectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardSectionAppBar({
    required this.title,
    required this.onBack,
    this.onRefresh,
    this.refreshLabel = 'Refresh',
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final String refreshLabel;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      actions: [
        if (onRefresh != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 40)),
              onPressed: onRefresh,
              child: Text(refreshLabel),
            ),
          ),
      ],
    );
  }
}

MhAccent accentForHubStat(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('ticket') || lower.contains('report')) return MhAccent.coral;
  if (lower.contains('pending') || lower.contains('processing')) return MhAccent.amber;
  if (lower.contains('review')) return MhAccent.violet;
  if (lower.contains('user')) return MhAccent.sky;
  if (lower.contains('business')) return MhAccent.mint;
  return MhAccent.sky;
}
