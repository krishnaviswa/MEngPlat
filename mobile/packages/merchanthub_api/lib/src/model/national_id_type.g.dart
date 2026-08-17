// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'national_id_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NationalIdType _$pan = const NationalIdType._('pan');
const NationalIdType _$aadhaar = const NationalIdType._('aadhaar');
const NationalIdType _$other = const NationalIdType._('other');

NationalIdType _$valueOf(String name) {
  switch (name) {
    case 'pan':
      return _$pan;
    case 'aadhaar':
      return _$aadhaar;
    case 'other':
      return _$other;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NationalIdType> _$values =
    BuiltSet<NationalIdType>(const <NationalIdType>[
  _$pan,
  _$aadhaar,
  _$other,
]);

class _$NationalIdTypeMeta {
  const _$NationalIdTypeMeta();
  NationalIdType get pan => _$pan;
  NationalIdType get aadhaar => _$aadhaar;
  NationalIdType get other => _$other;
  NationalIdType valueOf(String name) => _$valueOf(name);
  BuiltSet<NationalIdType> get values => _$values;
}

abstract class _$NationalIdTypeMixin {
  // ignore: non_constant_identifier_names
  _$NationalIdTypeMeta get NationalIdType => const _$NationalIdTypeMeta();
}

Serializer<NationalIdType> _$nationalIdTypeSerializer =
    _$NationalIdTypeSerializer();

class _$NationalIdTypeSerializer
    implements PrimitiveSerializer<NationalIdType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pan': 'pan',
    'aadhaar': 'aadhaar',
    'other': 'other',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pan': 'pan',
    'aadhaar': 'aadhaar',
    'other': 'other',
  };

  @override
  final Iterable<Type> types = const <Type>[NationalIdType];
  @override
  final String wireName = 'NationalIdType';

  @override
  Object serialize(Serializers serializers, NationalIdType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  NationalIdType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      NationalIdType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
