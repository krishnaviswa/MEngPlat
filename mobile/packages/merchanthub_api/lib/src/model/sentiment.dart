//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'sentiment.g.dart';

class Sentiment extends EnumClass {

  @BuiltValueEnumConst(wireName: r'positive')
  static const Sentiment positive = _$positive;
  @BuiltValueEnumConst(wireName: r'neutral')
  static const Sentiment neutral = _$neutral;
  @BuiltValueEnumConst(wireName: r'negative')
  static const Sentiment negative = _$negative;

  static Serializer<Sentiment> get serializer => _$sentimentSerializer;

  const Sentiment._(String name): super(name);

  static BuiltSet<Sentiment> get values => _$values;
  static Sentiment valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class SentimentMixin = Object with _$SentimentMixin;

