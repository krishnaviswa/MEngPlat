//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'business_report_admin_update.g.dart';

/// BusinessReportAdminUpdate
///
/// Properties:
/// * [status] 
@BuiltValue()
abstract class BusinessReportAdminUpdate implements Built<BusinessReportAdminUpdate, BusinessReportAdminUpdateBuilder> {
  @BuiltValueField(wireName: r'status')
  String get status;

  BusinessReportAdminUpdate._();

  factory BusinessReportAdminUpdate([void updates(BusinessReportAdminUpdateBuilder b)]) = _$BusinessReportAdminUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BusinessReportAdminUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BusinessReportAdminUpdate> get serializer => _$BusinessReportAdminUpdateSerializer();
}

class _$BusinessReportAdminUpdateSerializer implements PrimitiveSerializer<BusinessReportAdminUpdate> {
  @override
  final Iterable<Type> types = const [BusinessReportAdminUpdate, _$BusinessReportAdminUpdate];

  @override
  final String wireName = r'BusinessReportAdminUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BusinessReportAdminUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BusinessReportAdminUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BusinessReportAdminUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BusinessReportAdminUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BusinessReportAdminUpdateBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

