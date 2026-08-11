// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReviewStatus _$active = const ReviewStatus._('active');
const ReviewStatus _$hidden = const ReviewStatus._('hidden');
const ReviewStatus _$reported = const ReviewStatus._('reported');
const ReviewStatus _$removed = const ReviewStatus._('removed');

ReviewStatus _$valueOf(String name) {
  switch (name) {
    case 'active':
      return _$active;
    case 'hidden':
      return _$hidden;
    case 'reported':
      return _$reported;
    case 'removed':
      return _$removed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ReviewStatus> _$values =
    BuiltSet<ReviewStatus>(const <ReviewStatus>[
  _$active,
  _$hidden,
  _$reported,
  _$removed,
]);

class _$ReviewStatusMeta {
  const _$ReviewStatusMeta();
  ReviewStatus get active => _$active;
  ReviewStatus get hidden => _$hidden;
  ReviewStatus get reported => _$reported;
  ReviewStatus get removed => _$removed;
  ReviewStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<ReviewStatus> get values => _$values;
}

abstract class _$ReviewStatusMixin {
  // ignore: non_constant_identifier_names
  _$ReviewStatusMeta get ReviewStatus => const _$ReviewStatusMeta();
}

Serializer<ReviewStatus> _$reviewStatusSerializer = _$ReviewStatusSerializer();

class _$ReviewStatusSerializer implements PrimitiveSerializer<ReviewStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'active': 'active',
    'hidden': 'hidden',
    'reported': 'reported',
    'removed': 'removed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'active': 'active',
    'hidden': 'hidden',
    'reported': 'reported',
    'removed': 'removed',
  };

  @override
  final Iterable<Type> types = const <Type>[ReviewStatus];
  @override
  final String wireName = 'ReviewStatus';

  @override
  Object serialize(Serializers serializers, ReviewStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ReviewStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ReviewStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
