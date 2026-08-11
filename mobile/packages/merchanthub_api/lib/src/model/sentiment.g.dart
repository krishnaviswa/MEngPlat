// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentiment.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Sentiment _$positive = const Sentiment._('positive');
const Sentiment _$neutral = const Sentiment._('neutral');
const Sentiment _$negative = const Sentiment._('negative');

Sentiment _$valueOf(String name) {
  switch (name) {
    case 'positive':
      return _$positive;
    case 'neutral':
      return _$neutral;
    case 'negative':
      return _$negative;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<Sentiment> _$values = BuiltSet<Sentiment>(const <Sentiment>[
  _$positive,
  _$neutral,
  _$negative,
]);

class _$SentimentMeta {
  const _$SentimentMeta();
  Sentiment get positive => _$positive;
  Sentiment get neutral => _$neutral;
  Sentiment get negative => _$negative;
  Sentiment valueOf(String name) => _$valueOf(name);
  BuiltSet<Sentiment> get values => _$values;
}

abstract class _$SentimentMixin {
  // ignore: non_constant_identifier_names
  _$SentimentMeta get Sentiment => const _$SentimentMeta();
}

Serializer<Sentiment> _$sentimentSerializer = _$SentimentSerializer();

class _$SentimentSerializer implements PrimitiveSerializer<Sentiment> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'positive': 'positive',
    'neutral': 'neutral',
    'negative': 'negative',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'positive': 'positive',
    'neutral': 'neutral',
    'negative': 'negative',
  };

  @override
  final Iterable<Type> types = const <Type>[Sentiment];
  @override
  final String wireName = 'Sentiment';

  @override
  Object serialize(Serializers serializers, Sentiment object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  Sentiment deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      Sentiment.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
