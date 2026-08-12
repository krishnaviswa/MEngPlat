import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';

/// Regression coverage for the fix landed in commit 207abb7: `build()` must
/// *await* `authControllerProvider.future` rather than peek `.valueOrNull`,
/// so it can't resolve to `{}` before auth actually settles (which briefly
/// showed "Add review" on a merchant's own business, S-023 AC12). Mirrors
/// the already-correct pattern regression-tested for the favorites side in
/// `favorites_controller_test.dart`.

UserResponse _merchant() => UserResponse((b) => b
  ..id = 'merchant-1'
  ..email = 'merchant@example.com'
  ..fullName = 'Test Merchant'
  ..role = UserRole.merchant
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

UserResponse _customer() => UserResponse((b) => b
  ..id = 'customer-1'
  ..email = 'customer@example.com'
  ..fullName = 'Test Customer'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

BusinessResponse _business(String id) => BusinessResponse((b) => b
  ..id = id
  ..name = 'Owned Business'
  ..slug = 'owned-business'
  ..address = '1 Main St'
  ..city = 'Springfield'
  ..country = 'US'
  ..status = BusinessStatus.approved
  ..averageRating = 4.5
  ..reviewCount = 3);

/// Auth controller whose `build()` only resolves once [completer] completes
/// -- lets tests observe [myBusinessIdsProvider]'s state *while* auth is
/// still in flight, which is exactly the window the pre-fix race got wrong.
class _DelayedAuthController extends AuthController {
  _DelayedAuthController(this.completer);

  final Completer<UserResponse?> completer;

  @override
  Future<UserResponse?> build() => completer.future;
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository({this.mine = const []}) : super(ApiClient());

  final List<BusinessResponse> mine;
  int listMineCallCount = 0;

  @override
  Future<List<BusinessResponse>> listMine() async {
    listMineCallCount++;
    return mine;
  }
}

void main() {
  test(
    'myBusinessIdsProvider stays loading (never resolves early to {}) while auth is still settling',
    () async {
      final authCompleter = Completer<UserResponse?>();
      final businessRepository = _FakeBusinessRepository(mine: [_business('biz-owned')]);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _DelayedAuthController(authCompleter)),
          businessRepositoryProvider.overrideWithValue(businessRepository),
        ],
      );
      addTearDown(container.dispose);

      // Start listening before auth has settled -- this is the exact
      // sequencing the pre-fix `.valueOrNull` read got wrong.
      final resultFuture = container.read(myBusinessIdsProvider.future);

      // Let pending microtasks run without resolving auth yet.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // The bug: reading `.valueOrNull` synchronously returned null while
      // auth was loading, so the old code short-circuited to a *completed*
      // `{}` here instead of staying in a loading state until auth resolved.
      expect(
        container.read(myBusinessIdsProvider).isLoading,
        isTrue,
        reason: 'must not resolve before auth settles (async-dependency race regression)',
      );
      expect(businessRepository.listMineCallCount, 0);

      authCompleter.complete(_merchant());
      final result = await resultFuture;

      expect(result, {'biz-owned'});
      // >=1 rather than an exact count: watching `authControllerProvider.future`
      // subscribes to the whole provider, so its loading->data transition can
      // trigger a superseding rebuild in addition to resuming the suspended
      // await -- an accepted Riverpod quirk (see the identical note on
      // `FavoritedIdsController.build()`), not something this regression
      // test is about. What matters here is it never fired *before* auth
      // settled, and the final result is correct.
      expect(businessRepository.listMineCallCount, greaterThanOrEqualTo(1));
    },
  );

  test('myBusinessIdsProvider resolves to {} for a non-merchant once auth settles', () async {
    final authCompleter = Completer<UserResponse?>();
    final businessRepository = _FakeBusinessRepository(mine: [_business('should-not-be-fetched')]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _DelayedAuthController(authCompleter)),
        businessRepositoryProvider.overrideWithValue(businessRepository),
      ],
    );
    addTearDown(container.dispose);

    final resultFuture = container.read(myBusinessIdsProvider.future);
    authCompleter.complete(_customer());

    expect(await resultFuture, isEmpty);
    expect(businessRepository.listMineCallCount, 0);
  });

  test('myBusinessIdsProvider resolves to {} while logged out', () async {
    final authCompleter = Completer<UserResponse?>();
    final businessRepository = _FakeBusinessRepository(mine: [_business('should-not-be-fetched')]);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _DelayedAuthController(authCompleter)),
        businessRepositoryProvider.overrideWithValue(businessRepository),
      ],
    );
    addTearDown(container.dispose);

    final resultFuture = container.read(myBusinessIdsProvider.future);
    authCompleter.complete(null);

    expect(await resultFuture, isEmpty);
    expect(businessRepository.listMineCallCount, 0);
  });
}
