import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import 'auth_provider.dart';

/// Port for Google Identity ID-token (the `credential` `POST /auth/google` expects).
/// Tests fake this so widget tests never hit the real SDK.
abstract class GoogleSignInClient {
  bool get isConfigured;

  /// Returns the ID token, or `null` if the user cancelled.
  Future<String?> requestIdToken();
}

class UnconfiguredGoogleSignInClient implements GoogleSignInClient {
  const UnconfiguredGoogleSignInClient();

  @override
  bool get isConfigured => false;

  @override
  Future<String?> requestIdToken() async => null;
}

class PluginGoogleSignInClient implements GoogleSignInClient {
  PluginGoogleSignInClient(this.clientId);

  final String clientId;

  GoogleSignIn? _plugin;

  GoogleSignIn get _googleSignIn => _plugin ??= GoogleSignIn(
        clientId: clientId,
        serverClientId: clientId,
        scopes: const ['email', 'profile'],
      );

  @override
  bool get isConfigured => clientId.isNotEmpty;

  @override
  Future<String?> requestIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final token = auth.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('Google sign-in did not return an ID token');
    }
    return token;
  }
}

/// Prefer compile-time `--dart-define=GOOGLE_CLIENT_ID`; otherwise the API's public config.
String resolveGoogleClientId({required String baked, required String remote}) {
  if (baked.isNotEmpty) return baked;
  return remote;
}

final googleSignInClientProvider = FutureProvider<GoogleSignInClient>((ref) async {
  const baked = AppConfig.googleClientId;
  if (baked.isNotEmpty) return PluginGoogleSignInClient(baked);
  final remote = await ref.read(authRepositoryProvider).fetchGoogleClientId();
  final id = resolveGoogleClientId(baked: baked, remote: remote);
  if (id.isEmpty) return const UnconfiguredGoogleSignInClient();
  return PluginGoogleSignInClient(id);
});

bool googleSignInIsConfigured(AsyncValue<GoogleSignInClient> value) {
  return value.maybeWhen(data: (client) => client.isConfigured, orElse: () => false);
}
