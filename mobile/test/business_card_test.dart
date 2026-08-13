import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/auth/auth_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_card.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_providers.dart';
import 'package:merchanthub_mobile/features/favorites/favorites_repository.dart';

BusinessResponse _business({String? storefront}) => BusinessResponse((b) => b
  ..id = 'biz-1'
  ..name = 'Cafe Demo'
  ..slug = 'cafe-demo'
  ..address = '1 Main'
  ..city = 'Springfield'
  ..country = 'US'
  ..status = BusinessStatus.approved
  ..averageRating = 4.2
  ..reviewCount = 3
  ..storefrontUrl = storefront);

class _FakeAuth extends AuthController {
  @override
  Future<UserResponse?> build() async => null;
}

class _FakeFavorites extends FavoritesRepository {
  _FakeFavorites() : super(ApiClient());

  @override
  Future<List<BusinessResponse>> listFavorites() async => [];
}

void main() {
  testWidgets('AC11: storefront photo is shown when present', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuth.new),
          favoritesRepositoryProvider.overrideWithValue(_FakeFavorites()),
        ],
        child: MaterialApp(
          home: Scaffold(body: BusinessCard(business: _business(storefront: 'https://example.com/shop.jpg'))),
        ),
      ),
    );
    expect(find.byKey(const Key('businessPhoto')), findsOneWidget);
    expect(find.text('Cafe Demo'), findsOneWidget);
  });

  testWidgets('AC11: placeholder when there is no photo', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuth.new),
          favoritesRepositoryProvider.overrideWithValue(_FakeFavorites()),
        ],
        child: MaterialApp(home: Scaffold(body: BusinessCard(business: _business()))),
      ),
    );
    expect(find.byKey(const Key('businessPhotoPlaceholder')), findsOneWidget);
    expect(find.byKey(const Key('businessPhoto')), findsNothing);
  });
}
