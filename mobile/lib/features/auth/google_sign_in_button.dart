import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_sign_in_client.dart';

/// Matches web `GoogleSignInButton`: hidden when the client ID is unset.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({
    required this.onCredential,
    this.onError,
    this.enabled = true,
    super.key,
  });

  final Future<void> Function(String credential) onCredential;
  final ValueChanged<String>? onError;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncClient = ref.watch(googleSignInClientProvider);
    final client = asyncClient.valueOrNull;
    if (client == null || !client.isConfigured) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return FilledButton(
      key: const Key('googleSignInButton'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
      ),
      onPressed: enabled
          ? () async {
              try {
                final credential = await client.requestIdToken();
                if (credential == null) return;
                await onCredential(credential);
              } on GoogleSignInCancelled {
                return;
              } on GoogleSignInException catch (e) {
                onError?.call(e.message);
              } catch (e) {
                onError?.call(e.toString());
              }
            }
          : null,
      child: const Text('Continue with Google'),
    );
  }
}
