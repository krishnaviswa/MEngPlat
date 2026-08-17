import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../core/network/api_client.dart';
import 'auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

class AuthController extends AsyncNotifier<UserResponse?> {
  @override
  FutureOr<UserResponse?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    if (!await repository.hasSession()) return null;
    try {
      return await repository.me();
    } catch (_) {
      // Stored token is invalid/expired past the point a silent refresh can
      // save it -- treat as logged out rather than surfacing an error.
      return null;
    }
  }

  /// Returns the MFA challenge/enrollment gate; does not change [state] since
  /// a password account has no session yet at this point (see S-020).
  Future<LoginResult> submitCredentials({required String email, required String password}) {
    return ref.read(authRepositoryProvider).login(email: email, password: password);
  }

  Future<TotpSetupResponse> startTotpEnrollment({required String mfaToken}) {
    return ref.read(authRepositoryProvider).totpSetup(mfaToken: mfaToken);
  }

  Future<void> confirmTotpEnrollment({required String mfaToken, required String code}) async {
    final user = await ref.read(authRepositoryProvider).totpConfirm(mfaToken: mfaToken, code: code);
    state = AsyncValue.data(user);
  }

  Future<void> verifyTotp({required String mfaToken, required String code}) async {
    final user = await ref.read(authRepositoryProvider).totpVerify(mfaToken: mfaToken, code: code);
    state = AsyncValue.data(user);
  }

  /// Password register: no session until the user logs in and completes TOTP.
  Future<void> register({
    required String email,
    required String fullName,
    required String password,
    required UserRole role,
  }) {
    return ref.read(authRepositoryProvider).register(
          email: email,
          fullName: fullName,
          password: password,
          role: role,
        );
  }

  Future<void> signInWithGoogle({required String credential}) async {
    final user = await ref.read(authRepositoryProvider).loginWithGoogle(credential: credential);
    state = AsyncValue.data(user);
  }

  /// Request half of forgot/reset password (M-65); no session change.
  Future<MessageResponse> forgotPassword({required String email}) {
    return ref.read(authRepositoryProvider).forgotPassword(email: email);
  }

  /// Sends an SMS code; no session change (M-74).
  Future<MessageResponse> requestPhoneOtp({required String phone}) {
    return ref.read(authRepositoryProvider).requestPhoneOtp(phone: phone);
  }

  /// Login-or-register in one call; skips TOTP entirely (same trust model as
  /// Google, M-74).
  Future<void> signInWithPhone({
    required String phone,
    required String code,
    String? fullName,
    UserRole? role,
  }) async {
    final user = await ref.read(authRepositoryProvider).verifyPhoneOtp(
          phone: phone,
          code: code,
          fullName: fullName,
          role: role,
        );
    state = AsyncValue.data(user);
  }

  Future<UserResponse> updateProfile(UserProfileUpdate payload) async {
    final user = await ref.read(authRepositoryProvider).updateMe(payload);
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserResponse?>(AuthController.new);
