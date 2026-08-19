//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mock_aadhaar_otp_response.g.dart';

/// MockAadhaarOtpResponse
///
/// Properties:
/// * [message] 
/// * [devCode] 
@BuiltValue()
abstract class MockAadhaarOtpResponse implements Built<MockAadhaarOtpResponse, MockAadhaarOtpResponseBuilder> {
  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'dev_code')
  String? get devCode;

  MockAadhaarOtpResponse._();

  factory MockAadhaarOtpResponse([void updates(MockAadhaarOtpResponseBuilder b)]) = _$MockAadhaarOtpResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MockAadhaarOtpResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MockAadhaarOtpResponse> get serializer => _$MockAadhaarOtpResponseSerializer();
}

class _$MockAadhaarOtpResponseSerializer implements PrimitiveSerializer<MockAadhaarOtpResponse> {
  @override
  final Iterable<Type> types = const [MockAadhaarOtpResponse, _$MockAadhaarOtpResponse];

  @override
  final String wireName = r'MockAadhaarOtpResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MockAadhaarOtpResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    if (object.devCode != null) {
      yield r'dev_code';
      yield serializers.serialize(
        object.devCode,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MockAadhaarOtpResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MockAadhaarOtpResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'dev_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.devCode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MockAadhaarOtpResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MockAadhaarOtpResponseBuilder();
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

