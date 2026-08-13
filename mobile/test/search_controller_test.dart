import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/features/businesses/business_list_provider.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';
import 'package:merchanthub_mobile/features/businesses/maps_config.dart';
import 'package:merchanthub_mobile/features/businesses/search_controller.dart';
import 'package:merchanthub_mobile/features/businesses/search_query.dart';

BusinessResponse _biz(int n) => BusinessResponse((b) => b
  ..id = 'biz-$n'
  ..name = 'Biz $n'
  ..slug = 'biz-$n'
  ..address = '1 Main'
  ..city = 'Springfield'
  ..country = 'US'
  ..status = BusinessStatus.approved
  ..averageRating = 4
  ..reviewCount = 1);

class _FakeRepo extends BusinessRepository {
  _FakeRepo() : super(ApiClient());

  final calls = <({SearchQuery query, int page})>[];

  @override
  Future<List<BusinessResponse>> searchBusinesses({
    SearchQuery query = const SearchQuery(),
    int page = 1,
    int pageSize = SearchQuery.pageSize,
  }) async {
    calls.add((query: query, page: page));
    if (page == 1) {
      return [for (var i = 0; i < SearchQuery.pageSize; i++) _biz(i)];
    }
    if (page == 2) {
      return [_biz(100), _biz(101), _biz(102)];
    }
    return [];
  }

  @override
  Future<MapsConfig> mapsConfig() async => MapsConfig.fallback;
}

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(overrides: [businessRepositoryProvider.overrideWithValue(repo)]);
  });

  tearDown(() => container.dispose());

  test('AC1/AC2: applyQuery sends q and clearing omits it', () async {
    await container.read(searchControllerProvider.future);
    await container.read(searchControllerProvider.notifier).applyQuery(const SearchQuery(q: 'cafe'));
    expect(repo.calls.last.query.q, 'cafe');

    await container.read(searchControllerProvider.notifier).applyQuery(const SearchQuery());
    expect(repo.calls.last.query.q, isNull);
  });

  test('AC3: filters city, category, minRating, sort', () async {
    await container.read(searchControllerProvider.future);
    await container.read(searchControllerProvider.notifier).applyQuery(
          const SearchQuery(city: 'Chennai', category: 'cafe', minRating: 4, sort: 'name'),
        );
    final q = repo.calls.last.query;
    expect(q.city, 'Chennai');
    expect(q.category, 'cafe');
    expect(q.minRating, 4);
    expect(q.sort, 'name');
    expect(repo.calls.last.page, 1);
  });

  test('AC7: radiusKm is sent with location', () async {
    await container.read(searchControllerProvider.future);
    await container.read(searchControllerProvider.notifier).applyQuery(
          const SearchQuery(lat: 13, lng: 80, radiusKm: 25),
        );
    expect(repo.calls.last.query.radiusKm, 25);
    expect(repo.calls.last.query.hasLocation, isTrue);
  });

  test('AC10: loadMore requests page 2 and stops after a short page', () async {
    final first = await container.read(searchControllerProvider.future);
    expect(first.items.length, SearchQuery.pageSize);
    expect(first.hasMore, isTrue);

    await container.read(searchControllerProvider.notifier).loadMore();
    final second = container.read(searchControllerProvider).valueOrNull!;
    expect(second.page, 2);
    expect(second.items.length, SearchQuery.pageSize + 3);
    expect(second.hasMore, isFalse);

    await container.read(searchControllerProvider.notifier).loadMore();
    expect(repo.calls.where((c) => c.page == 3), isEmpty);
  });
}
