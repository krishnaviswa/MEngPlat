//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'business_report_create.g.dart';

/// BusinessReportCreate
///
/// Properties:
/// * [reason] 
@BuiltValue()
abstract class BusinessReportCreate implements Built<BusinessReportCreate, BusinessReportCreateBuilder> {
  @BuiltValueField(wireName: r'reason')
  String get reason;

  BusinessReportCreate._();

  factory BusinessReportCreate([void updates(BusinessReportCreateBuilder b)]) = _$BusinessReportCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BusinessReportCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BusinessReportCreate> get serializer => _$BusinessReportCreateSerializer();
}

class _$BusinessReportCreateSerializer implements PrimitiveSerializer<BusinessReportCreate> {
  @override
  final Iterable<Type> types = const [BusinessReportCreate, _$BusinessReportCreate];

  @override
  final String wireName = r'BusinessReportCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BusinessReportCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BusinessReportCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BusinessReportCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BusinessReportCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BusinessReportCreateBuilder();
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

