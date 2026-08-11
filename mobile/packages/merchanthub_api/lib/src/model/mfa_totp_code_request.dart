//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mfa_totp_code_request.g.dart';

/// MfaTotpCodeRequest
///
/// Properties:
/// * [mfaToken] 
/// * [code] 
@BuiltValue()
abstract class MfaTotpCodeRequest implements Built<MfaTotpCodeRequest, MfaTotpCodeRequestBuilder> {
  @BuiltValueField(wireName: r'mfa_token')
  String get mfaToken;

  @BuiltValueField(wireName: r'code')
  String get code;

  MfaTotpCodeRequest._();

  factory MfaTotpCodeRequest([void updates(MfaTotpCodeRequestBuilder b)]) = _$MfaTotpCodeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MfaTotpCodeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MfaTotpCodeRequest> get serializer => _$MfaTotpCodeRequestSerializer();
}

class _$MfaTotpCodeRequestSerializer implements PrimitiveSerializer<MfaTotpCodeRequest> {
  @override
  final Iterable<Type> types = const [MfaTotpCodeRequest, _$MfaTotpCodeRequest];

  @override
  final String wireName = r'MfaTotpCodeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MfaTotpCodeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mfa_token';
    yield serializers.serialize(
      object.mfaToken,
      specifiedType: const FullType(String),
    );
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MfaTotpCodeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MfaTotpCodeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mfa_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mfaToken = valueDes;
          break;
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
  MfaTotpCodeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MfaTotpCodeRequestBuilder();
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

