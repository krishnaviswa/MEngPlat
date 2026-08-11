import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';

UserResponse _customer() => UserResponse((b) => b
  ..id = 'customer-1'
  ..email = 'customer@example.com'
  ..fullName = 'Test Customer'
  ..role = UserRole.customer
  ..isActive = true
  ..createdAt = DateTime.utc(2026, 1, 1));

class _FakeAuthController extends AuthController {
  @override
  Future<UserResponse?> build() async => _customer();
}

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository({this.failOnAdd = false}) : super(ApiClient());

  final bool failOnAdd;

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];

  @override
  Future<void> addFavorite(String businessId) async {
    if (failOnAdd) throw ApiException('Could not add favorite');
  }

  @override
  Future<void> removeFavorite(String businessId) async {}
}

void main() {
  test('toggle optimistically adds then removes a business id', () async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository()),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(favoritedIdsProvider.future), isEmpty);

    final notifier = container.read(favoritedIdsProvider.notifier);
    await notifier.toggle('biz-1');
    expect(container.read(favoritedIdsProvider).value, {'biz-1'});

    await notifier.toggle('biz-1');
    expect(container.read(favoritedIdsProvider).value, isEmpty);
  });

  test('toggle reverts the optimistic update when the API call fails', () async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuthController.new),
        favoritesRepositoryProvider.overrideWithValue(_FakeFavoritesRepository(failOnAdd: true)),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(favoritedIdsProvider.future), isEmpty);

    final notifier = container.read(favoritedIdsProvider.notifier);
    await expectLater(notifier.toggle('biz-1'), throwsA(isA<ApiException>()));
    expect(container.read(favoritedIdsProvider).value, isEmpty);
  });
}
