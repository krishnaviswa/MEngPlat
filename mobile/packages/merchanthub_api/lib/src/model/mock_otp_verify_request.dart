//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mock_otp_verify_request.g.dart';

/// MockOtpVerifyRequest
///
/// Properties:
/// * [code] 
@BuiltValue()
abstract class MockOtpVerifyRequest implements Built<MockOtpVerifyRequest, MockOtpVerifyRequestBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  MockOtpVerifyRequest._();

  factory MockOtpVerifyRequest([void updates(MockOtpVerifyRequestBuilder b)]) = _$MockOtpVerifyRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MockOtpVerifyRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MockOtpVerifyRequest> get serializer => _$MockOtpVerifyRequestSerializer();
}

class _$MockOtpVerifyRequestSerializer implements PrimitiveSerializer<MockOtpVerifyRequest> {
  @override
  final Iterable<Type> types = const [MockOtpVerifyRequest, _$MockOtpVerifyRequest];

  @override
  final String wireName = r'MockOtpVerifyRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MockOtpVerifyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MockOtpVerifyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MockOtpVerifyRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MockOtpVerifyRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MockOtpVerifyRequestBuilder();
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

