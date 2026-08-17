//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/user_role.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'phone_otp_verify_request.g.dart';

/// PhoneOtpVerifyRequest
///
/// Properties:
/// * [phone] 
/// * [code] 
/// * [fullName] 
/// * [role] 
@BuiltValue()
abstract class PhoneOtpVerifyRequest implements Built<PhoneOtpVerifyRequest, PhoneOtpVerifyRequestBuilder> {
  @BuiltValueField(wireName: r'phone')
  String get phone;

  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'full_name')
  String? get fullName;

  @BuiltValueField(wireName: r'role')
  UserRole? get role;
  // enum roleEnum {  customer,  merchant,  admin,  };

  PhoneOtpVerifyRequest._();

  factory PhoneOtpVerifyRequest([void updates(PhoneOtpVerifyRequestBuilder b)]) = _$PhoneOtpVerifyRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhoneOtpVerifyRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhoneOtpVerifyRequest> get serializer => _$PhoneOtpVerifyRequestSerializer();
}

class _$PhoneOtpVerifyRequestSerializer implements PrimitiveSerializer<PhoneOtpVerifyRequest> {
  @override
  final Iterable<Type> types = const [PhoneOtpVerifyRequest, _$PhoneOtpVerifyRequest];

  @override
  final String wireName = r'PhoneOtpVerifyRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhoneOtpVerifyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'phone';
    yield serializers.serialize(
      object.phone,
      specifiedType: const FullType(String),
    );
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    if (object.fullName != null) {
      yield r'full_name';
      yield serializers.serialize(
        object.fullName,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.role != null) {
      yield r'role';
      yield serializers.serialize(
        object.role,
        specifiedType: const FullType(UserRole),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PhoneOtpVerifyRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhoneOtpVerifyRequestBuilder result,
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
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'full_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.fullName = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserRole),
          ) as UserRole;
          result.role = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhoneOtpVerifyRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhoneOtpVerifyRequestBuilder();
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

