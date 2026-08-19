//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'business_report_message_create.g.dart';

/// BusinessReportMessageCreate
///
/// Properties:
/// * [body] 
@BuiltValue()
abstract class BusinessReportMessageCreate implements Built<BusinessReportMessageCreate, BusinessReportMessageCreateBuilder> {
  @BuiltValueField(wireName: r'body')
  String get body;

  BusinessReportMessageCreate._();

  factory BusinessReportMessageCreate([void updates(BusinessReportMessageCreateBuilder b)]) = _$BusinessReportMessageCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BusinessReportMessageCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BusinessReportMessageCreate> get serializer => _$BusinessReportMessageCreateSerializer();
}

class _$BusinessReportMessageCreateSerializer implements PrimitiveSerializer<BusinessReportMessageCreate> {
  @override
  final Iterable<Type> types = const [BusinessReportMessageCreate, _$BusinessReportMessageCreate];

  @override
  final String wireName = r'BusinessReportMessageCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BusinessReportMessageCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'body';
    yield serializers.serialize(
      object.body,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BusinessReportMessageCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BusinessReportMessageCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'body':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.body = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BusinessReportMessageCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BusinessReportMessageCreateBuilder();
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

