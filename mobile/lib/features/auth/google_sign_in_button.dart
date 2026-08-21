import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_sign_in_client.dart';

/// Matches web `GoogleSignInButton`: hidden when the client ID is unset.
/// S-116: filled surface so it reads as a button on [MhCanvas], not outline-only.
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
    return OutlinedButton(
      key: const Key('googleSignInButton'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.35), width: 1.5),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.g_mobiledata, size: 22),
          SizedBox(width: 4),
          Flexible(
            child: Text('Continue with Google', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
