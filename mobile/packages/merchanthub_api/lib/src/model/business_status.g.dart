// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'business_status.dart';

const BusinessStatus _$pending = const BusinessStatus._('pending');
const BusinessStatus _$processing = const BusinessStatus._('processing');
const BusinessStatus _$approved = const BusinessStatus._('approved');
const BusinessStatus _$rejected = const BusinessStatus._('rejected');
const BusinessStatus _$suspended = const BusinessStatus._('suspended');

BusinessStatus _$valueOf(String name) {
  switch (name) {
    case 'pending':
      return _$pending;
    case 'processing':
      return _$processing;
    case 'approved':
      return _$approved;
    case 'rejected':
      return _$rejected;
    case 'suspended':
      return _$suspended;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<BusinessStatus> _$values =
    BuiltSet<BusinessStatus>(const <BusinessStatus>[
  _$pending,
  _$processing,
  _$approved,
  _$rejected,
  _$suspended,
]);

class _$BusinessStatusMeta {
  const _$BusinessStatusMeta();
  BusinessStatus get pending => _$pending;
  BusinessStatus get processing => _$processing;
  BusinessStatus get approved => _$approved;
  BusinessStatus get rejected => _$rejected;
  BusinessStatus get suspended => _$suspended;
  BusinessStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<BusinessStatus> get values => _$values;
}

abstract class _$BusinessStatusMixin {
  _$BusinessStatusMeta get BusinessStatus => const _$BusinessStatusMeta();
}

Serializer<BusinessStatus> _$businessStatusSerializer =
    _$BusinessStatusSerializer();

class _$BusinessStatusSerializer implements PrimitiveSerializer<BusinessStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'processing': 'processing',
    'approved': 'approved',
    'rejected': 'rejected',
    'suspended': 'suspended',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'processing': 'processing',
    'approved': 'approved',
    'rejected': 'rejected',
    'suspended': 'suspended',
  };

  @override
  final Iterable<Type> types = const <Type>[BusinessStatus];
  @override
  final String wireName = 'BusinessStatus';

  @override
  Object serialize(Serializers serializers, BusinessStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  BusinessStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      BusinessStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}
