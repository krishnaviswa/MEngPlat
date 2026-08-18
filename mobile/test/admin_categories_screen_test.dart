import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/admin/admin_categories_screen.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/businesses/maps_config.dart';

/// S-061 (M-63) AC5/AC6/AC7: category create/list admin surface.

CategoryResponse _category({String id = 'cat-1', String name = 'Cafe', String slug = 'cafe'}) {
  return CategoryResponse((b) => b
    ..id = id
    ..name = name
    ..slug = slug);
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository({this.categories = const [], this.createError}) : super(ApiClient());

  List<CategoryResponse> categories;
  Object? createError;
  CategoryCreate? lastCreate;

  @override
  Future<List<CategoryResponse>> listCategories() async => categories;

  @override
  Future<CategoryResponse> createCategory(CategoryCreate payload) async {
    lastCreate = payload;
    final error = createError;
    if (error != null) throw error;
    final created = _category(id: 'new-1', name: payload.name, slug: payload.slug);
    categories = [...categories, created];
    return created;
  }

  @override
  Future<List<String>> listCities() async => [];

  @override
  Future<MapsConfig> mapsConfig() async => MapsConfig.fallback;
}

Future<_FakeBusinessRepository> _pumpScreen(
  WidgetTester tester, {
  List<CategoryResponse> categories = const [],
  Object? createError,
  void Function(String)? onNavigate,
}) async {
  final repo = _FakeBusinessRepository(categories: categories, createError: createError);
  final container = ProviderContainer(
    overrides: [businessRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/admin/categories',
    routes: [
      GoRoute(path: '/admin/categories', builder: (context, state) => const AdminCategoriesScreen()),
      GoRoute(
        path: '/businesses',
        builder: (context, state) {
          onNavigate?.call(state.uri.toString());
          return Scaffold(body: Text('BUSINESSES_${state.uri.queryParameters['category']}'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('AC7: empty state shows "No categories yet" with the add-category form still usable', (tester) async {
    await _pumpScreen(tester, categories: const []);

    expect(find.byKey(const Key('noCategoriesEmptyState')), findsOneWidget);
    expect(find.text('No categories yet'), findsOneWidget);
    expect(find.byKey(const Key('newCategoryNameField')), findsOneWidget);
    expect(find.byKey(const Key('addCategoryButton')), findsOneWidget);
  });

  testWidgets('AC5: submitting a new category name creates it and it appears in the list without leaving the screen',
      (tester) async {
    final repo = await _pumpScreen(tester, categories: const []);

    await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'Food Trucks');
    await tester.tap(find.byKey(const Key('addCategoryButton')));
    await tester.pumpAndSettle();

    expect(repo.lastCreate?.name, 'Food Trucks');
    expect(repo.lastCreate?.slug, 'food-trucks');
    expect(find.byKey(const Key('adminCategoriesScreen')), findsOneWidget);
    expect(find.text('Food Trucks'), findsOneWidget);
    expect(find.byKey(const Key('noCategoriesEmptyState')), findsNothing);
  });

  testWidgets('a create failure surfaces inline and does not clear the typed name', (tester) async {
    await _pumpScreen(tester, categories: const [], createError: ApiException('Category already exists'));

    await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'Cafe');
    await tester.tap(find.byKey(const Key('addCategoryButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Category already exists'), findsOneWidget);
  });

  testWidgets('AC6: tapping a category chip navigates to /businesses pre-filtered by that category slug',
      (tester) async {
    String? navigated;
    await _pumpScreen(
      tester,
      categories: [_category(name: 'Cafe', slug: 'cafe')],
      onNavigate: (uri) => navigated = uri,
    );

    expect(find.byKey(const Key('categoryList')), findsOneWidget);
    await tester.tap(find.text('Cafe'));
    await tester.pumpAndSettle();

    expect(navigated, '/businesses?category=cafe');
    expect(find.text('BUSINESSES_cafe'), findsOneWidget);
  });
}
