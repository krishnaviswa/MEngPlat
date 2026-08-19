import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_sign_in_client.dart';

/// Matches web `GoogleSignInButton`: hidden when the client ID is unset.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({required this.onCredential, this.enabled = true, super.key});

  final Future<void> Function(String credential) onCredential;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncClient = ref.watch(googleSignInClientProvider);
    final client = asyncClient.valueOrNull;
    if (client == null || !client.isConfigured) return const SizedBox.shrink();

    return OutlinedButton(
      key: const Key('googleSignInButton'),
      onPressed: enabled
          ? () async {
              final credential = await client.requestIdToken();
              if (credential == null) return;
              await onCredential(credential);
            }
          : null,
      child: const Text('Continue with Google'),
    );
  }
}
