import 'package:flutter_test/flutter_test.dart';
import 'package:merchanthub_mobile/features/merchant/country_state.dart';

void main() {
  test('India includes Tamil Nadu as TN', () {
    final states = getStatesForCountry('IN');
    expect(states.any((s) => s.code == 'TN' && s.name == 'Tamil Nadu'), isTrue);
  });

  test('matchingStateCode accepts name or code', () {
    expect(matchingStateCode('IN', 'TN'), 'TN');
    expect(matchingStateCode('IN', 'Tamil Nadu'), 'TN');
  });

  test('citySuggestions merges India defaults and typed city', () {
    final cities = citySuggestions(countryCode: 'IN', fromApi: ['Salem'], current: 'Erode');
    expect(cities, containsAll(['Chennai', 'Salem', 'Erode']));
  });
}
