import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Explicit Admin Home back control (M-86). Always returns to `/admin`.
AppBar adminBackAppBar(BuildContext context, {required String title, List<Widget>? actions}) {
  return AppBar(
    leading: IconButton(
      key: const Key('adminBackLink'),
      tooltip: 'Admin',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.go('/admin'),
    ),
    title: Text(title),
    actions: actions,
  );
}
