import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/core/collect_deep_link.dart';

void main() {
  test('collectAppLink is a merchanthub:// URI with /collect/', () {
    expect(collectAppLink('joes-diner'), 'merchanthub://app/collect/joes-diner');
    expect(
      collectAppLink('550e8400-e29b-41d4-a716-446655440000'),
      'merchanthub://app/collect/550e8400-e29b-41d4-a716-446655440000',
    );
  });

  test('collectLocationFromUri maps app and https collect URLs', () {
    expect(
      collectLocationFromUri(Uri.parse('merchanthub://app/collect/joes-diner')),
      '/collect/joes-diner',
    );
    expect(
      collectLocationFromUri(Uri.parse('https://example.com/collect/abc-uuid')),
      '/collect/abc-uuid',
    );
    expect(collectLocationFromUri(Uri.parse('https://example.com/home')), isNull);
  });
}
