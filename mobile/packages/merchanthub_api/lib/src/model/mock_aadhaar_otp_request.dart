//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mock_aadhaar_otp_request.g.dart';

/// MockAadhaarOtpRequest
///
/// Properties:
/// * [aadhaarNumber] 
@BuiltValue()
abstract class MockAadhaarOtpRequest implements Built<MockAadhaarOtpRequest, MockAadhaarOtpRequestBuilder> {
  @BuiltValueField(wireName: r'aadhaar_number')
  String get aadhaarNumber;

  MockAadhaarOtpRequest._();

  factory MockAadhaarOtpRequest([void updates(MockAadhaarOtpRequestBuilder b)]) = _$MockAadhaarOtpRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MockAadhaarOtpRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MockAadhaarOtpRequest> get serializer => _$MockAadhaarOtpRequestSerializer();
}

class _$MockAadhaarOtpRequestSerializer implements PrimitiveSerializer<MockAadhaarOtpRequest> {
  @override
  final Iterable<Type> types = const [MockAadhaarOtpRequest, _$MockAadhaarOtpRequest];

  @override
  final String wireName = r'MockAadhaarOtpRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MockAadhaarOtpRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'aadhaar_number';
    yield serializers.serialize(
      object.aadhaarNumber,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MockAadhaarOtpRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MockAadhaarOtpRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'aadhaar_number':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.aadhaarNumber = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MockAadhaarOtpRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MockAadhaarOtpRequestBuilder();
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

