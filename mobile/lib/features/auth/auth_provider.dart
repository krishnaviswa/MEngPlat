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

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserResponse?>(AuthController.new);
