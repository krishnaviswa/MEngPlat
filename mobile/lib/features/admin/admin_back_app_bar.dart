import 'package:flutter/material.dart';

import '../../ui/nav.dart';

/// Explicit Admin Home back control (M-86). Pops the admin stack when possible.
AppBar adminBackAppBar(BuildContext context, {required String title, List<Widget>? actions}) {
  return AppBar(
    leading: IconButton(
      key: const Key('adminBackLink'),
      tooltip: 'Admin',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => popOrGo(context, '/admin'),
    ),
    title: Text(title),
    actions: actions,
  );
}
