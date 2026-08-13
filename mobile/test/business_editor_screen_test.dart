import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/merchant/business_editor_screen.dart';

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository() : super(ApiClient());

  BusinessCreate? created;

  @override
  Future<List<CategoryResponse>> listCategories() async => [];

  @override
  Future<List<String>> listCities() async => [];

  @override
  Future<BusinessResponse> createBusiness(BusinessCreate payload) async {
    created = payload;
    return BusinessResponse((b) => b
      ..id = 'new-1'
      ..name = payload.name
      ..slug = 'new-1'
      ..address = payload.address
      ..city = payload.city
      ..country = payload.country ?? 'IN'
      ..status = BusinessStatus.pending
      ..averageRating = 0
      ..reviewCount = 0);
  }
}

void main() {
  testWidgets('S-031 AC13: empty name/address/city blocks create', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BusinessEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pump();
    expect(repo.created, isNull);
    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('S-031 AC13: valid name/address/city posts create', (tester) async {
    final repo = _FakeBusinessRepository();
    final container = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/new',
      routes: [
        GoRoute(path: '/new', builder: (context, state) => const BusinessEditorScreen()),
        GoRoute(path: '/merchant', builder: (context, state) => const Text('Merchant home')),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('businessNameField')), 'New Shop');
    await tester.enterText(find.byKey(const Key('businessAddressField')), '2 Oak');
    await tester.enterText(find.byKey(const Key('businessCityField')), 'Springfield');
    await tester.ensureVisible(find.byKey(const Key('businessEditorSave')));
    await tester.tap(find.byKey(const Key('businessEditorSave')));
    await tester.pump();
    expect(repo.created?.name, 'New Shop');
  });
}
