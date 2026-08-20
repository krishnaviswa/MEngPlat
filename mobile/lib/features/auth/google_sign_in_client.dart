import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import 'auth_provider.dart';

/// User dismissed the account picker. Not an error — callers stay silent.
class GoogleSignInCancelled implements Exception {}

/// Picker or token failure that the Login/Register screen should show.
class GoogleSignInException implements Exception {
  GoogleSignInException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Port for Google Identity ID-token (the `credential` `POST /auth/google` expects).
/// Tests fake this so widget tests never hit the real SDK.
abstract class GoogleSignInClient {
  bool get isConfigured;

  /// Returns the ID token, or `null` / [GoogleSignInCancelled] if the user cancelled.
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
  PluginGoogleSignInClient(this.serverClientId);

  /// Web OAuth client ID — Android `serverClientId` only so the ID token `aud`
  /// matches backend `GOOGLE_CLIENT_ID`. Do not pass this as Android `clientId`.
  final String serverClientId;

  GoogleSignIn? _plugin;

  GoogleSignIn get _googleSignIn => _plugin ??= GoogleSignIn(
        serverClientId: serverClientId,
        scopes: const ['email', 'profile'],
      );

  @override
  bool get isConfigured => serverClientId.isNotEmpty;

  @override
  Future<String?> requestIdToken() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        throw GoogleSignInException(
          'Google did not return an ID token. Check that the Web client ID is set as serverClientId.',
        );
      }
      return token;
    } on GoogleSignInException {
      rethrow;
    } catch (e) {
      final text = e.toString();
      if (_isCancel(text)) throw GoogleSignInCancelled();
      if (_isDeveloperError(text)) {
        throw GoogleSignInException(
          'Google sign-in is not configured for this app build (SHA-1 / Android OAuth client).',
        );
      }
      throw GoogleSignInException(text);
    }
  }

  static bool _isCancel(String text) {
    final lower = text.toLowerCase();
    return lower.contains('canceled') ||
        lower.contains('cancelled') ||
        lower.contains('signin_cancelled') ||
        lower.contains('12501');
  }

  static bool _isDeveloperError(String text) {
    final lower = text.toLowerCase();
    return lower.contains('apiexception: 10') ||
        lower.contains('developer_error') ||
        lower.contains('api_not_connected') ||
        lower.contains(': 10,') ||
        lower.contains('status{statuscode=developer_error');
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
