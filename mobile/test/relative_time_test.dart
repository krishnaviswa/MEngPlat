import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/notifications/relative_time.dart';

void main() {
  final now = DateTime.utc(2026, 1, 10, 12, 0, 0);

  test('formats sub-minute durations as "just now"', () {
    expect(formatRelativeTime(now.subtract(const Duration(seconds: 10)), now: now), 'just now');
  });

  test('formats minutes', () {
    expect(formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
  });

  test('formats hours', () {
    expect(formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
  });

  test('formats days', () {
    expect(formatRelativeTime(now.subtract(const Duration(days: 2)), now: now), '2d ago');
  });

  test('formats weeks', () {
    expect(formatRelativeTime(now.subtract(const Duration(days: 14)), now: now), '2w ago');
  });
}
