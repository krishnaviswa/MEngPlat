import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/core/network/api_client.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/features/businesses/business_repository.dart';

BusinessResponse _biz({String id = 'biz-1', String slug = 'joes-diner'}) {
  return BusinessResponse((b) => b
    ..id = id
    ..name = "Joe's Diner"
    ..slug = slug
    ..address = '1 Main St'
    ..city = 'Springfield'
    ..country = 'US'
    ..status = BusinessStatus.approved
    ..averageRating = 4.5
    ..reviewCount = 2);
}

class _FakeRepo extends BusinessRepository {
  _FakeRepo({this.onSlug, this.onId}) : super(ApiClient());

  final Future<BusinessResponse> Function(String slug)? onSlug;
  final Future<BusinessResponse> Function(String id)? onId;

  @override
  Future<BusinessResponse> getBySlug(String slug) => onSlug!(slug);

  @override
  Future<BusinessResponse> getById(String businessId) => onId!(businessId);
}

void main() {
  test('isCollectUuid matches the web collect UUID regex', () {
    expect(isCollectUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
    expect(isCollectUuid('joes-diner'), isFalse);
    expect(isCollectUuid('550e8400e29b41d4a716446655440000'), isFalse);
  });

  test('resolveCollectTarget uses getById for a UUID without calling slug', () async {
    var slugCalls = 0;
    var idCalls = 0;
    final repo = _FakeRepo(
      onSlug: (_) {
        slugCalls++;
        throw StateError('slug must not run for UUID');
      },
      onId: (id) async {
        idCalls++;
        return _biz(id: id);
      },
    );

    final found = await repo.resolveCollectTarget('550e8400-e29b-41d4-a716-446655440000');
    expect(found.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(slugCalls, 0);
    expect(idCalls, 1);
  });

  test('resolveCollectTarget falls back to getById when slug returns 404', () async {
    final repo = _FakeRepo(
      onSlug: (_) async => throw ApiException('Business not found', statusCode: 404),
      onId: (id) async => _biz(id: id, slug: 'fallback'),
    );

    final found = await repo.resolveCollectTarget('not-a-uuid-but-maybe-id');
    expect(found.slug, 'fallback');
  });
}
