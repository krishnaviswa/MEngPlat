// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DraftStatus _$pending = const DraftStatus._('pending');
const DraftStatus _$applied = const DraftStatus._('applied');
const DraftStatus _$discarded = const DraftStatus._('discarded');

DraftStatus _$valueOf(String name) {
  switch (name) {
    case 'pending':
      return _$pending;
    case 'applied':
      return _$applied;
    case 'discarded':
      return _$discarded;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DraftStatus> _$values =
    BuiltSet<DraftStatus>(const <DraftStatus>[
  _$pending,
  _$applied,
  _$discarded,
]);

class _$DraftStatusMeta {
  const _$DraftStatusMeta();
  DraftStatus get pending => _$pending;
  DraftStatus get applied => _$applied;
  DraftStatus get discarded => _$discarded;
  DraftStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DraftStatus> get values => _$values;
}

abstract class _$DraftStatusMixin {
  // ignore: non_constant_identifier_names
  _$DraftStatusMeta get DraftStatus => const _$DraftStatusMeta();
}

Serializer<DraftStatus> _$draftStatusSerializer = _$DraftStatusSerializer();

class _$DraftStatusSerializer implements PrimitiveSerializer<DraftStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'applied': 'applied',
    'discarded': 'discarded',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'applied': 'applied',
    'discarded': 'discarded',
  };

  @override
  final Iterable<Type> types = const <Type>[DraftStatus];
  @override
  final String wireName = 'DraftStatus';

  @override
  Object serialize(Serializers serializers, DraftStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DraftStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DraftStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
