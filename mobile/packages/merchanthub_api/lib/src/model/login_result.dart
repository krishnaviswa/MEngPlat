//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'login_result.g.dart';

/// Password login: either full tokens, or an MFA challenge / enrollment gate.
///
/// Properties:
/// * [accessToken] 
/// * [refreshToken] 
/// * [tokenType] 
/// * [mfaRequired] 
/// * [mfaEnrollmentRequired] 
/// * [mfaToken] 
@BuiltValue()
abstract class LoginResult implements Built<LoginResult, LoginResultBuilder> {
  @BuiltValueField(wireName: r'access_token')
  String? get accessToken;

  @BuiltValueField(wireName: r'refresh_token')
  String? get refreshToken;

  @BuiltValueField(wireName: r'token_type')
  String? get tokenType;

  @BuiltValueField(wireName: r'mfa_required')
  bool? get mfaRequired;

  @BuiltValueField(wireName: r'mfa_enrollment_required')
  bool? get mfaEnrollmentRequired;

  @BuiltValueField(wireName: r'mfa_token')
  String? get mfaToken;

  LoginResult._();

  factory LoginResult([void updates(LoginResultBuilder b)]) = _$LoginResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LoginResultBuilder b) => b
      ..tokenType = 'bearer'
      ..mfaRequired = false
      ..mfaEnrollmentRequired = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<LoginResult> get serializer => _$LoginResultSerializer();
}

class _$LoginResultSerializer implements PrimitiveSerializer<LoginResult> {
  @override
  final Iterable<Type> types = const [LoginResult, _$LoginResult];

  @override
  final String wireName = r'LoginResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LoginResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.accessToken != null) {
      yield r'access_token';
      yield serializers.serialize(
        object.accessToken,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.refreshToken != null) {
      yield r'refresh_token';
      yield serializers.serialize(
        object.refreshToken,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.tokenType != null) {
      yield r'token_type';
      yield serializers.serialize(
        object.tokenType,
        specifiedType: const FullType(String),
      );
    }
    if (object.mfaRequired != null) {
      yield r'mfa_required';
      yield serializers.serialize(
        object.mfaRequired,
        specifiedType: const FullType(bool),
      );
    }
    if (object.mfaEnrollmentRequired != null) {
      yield r'mfa_enrollment_required';
      yield serializers.serialize(
        object.mfaEnrollmentRequired,
        specifiedType: const FullType(bool),
      );
    }
    if (object.mfaToken != null) {
      yield r'mfa_token';
      yield serializers.serialize(
        object.mfaToken,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    LoginResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LoginResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'access_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.accessToken = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.refreshToken = valueDes;
          break;
        case r'token_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tokenType = valueDes;
          break;
        case r'mfa_required':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.mfaRequired = valueDes;
          break;
        case r'mfa_enrollment_required':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.mfaEnrollmentRequired = valueDes;
          break;
        case r'mfa_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.mfaToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LoginResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LoginResultBuilder();
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

