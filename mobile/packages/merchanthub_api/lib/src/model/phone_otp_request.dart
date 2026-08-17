//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'phone_otp_request.g.dart';

/// PhoneOtpRequest
///
/// Properties:
/// * [phone] 
@BuiltValue()
abstract class PhoneOtpRequest implements Built<PhoneOtpRequest, PhoneOtpRequestBuilder> {
  @BuiltValueField(wireName: r'phone')
  String get phone;

  PhoneOtpRequest._();

  factory PhoneOtpRequest([void updates(PhoneOtpRequestBuilder b)]) = _$PhoneOtpRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhoneOtpRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhoneOtpRequest> get serializer => _$PhoneOtpRequestSerializer();
}

class _$PhoneOtpRequestSerializer implements PrimitiveSerializer<PhoneOtpRequest> {
  @override
  final Iterable<Type> types = const [PhoneOtpRequest, _$PhoneOtpRequest];

  @override
  final String wireName = r'PhoneOtpRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhoneOtpRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'phone';
    yield serializers.serialize(
      object.phone,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PhoneOtpRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhoneOtpRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhoneOtpRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhoneOtpRequestBuilder();
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

