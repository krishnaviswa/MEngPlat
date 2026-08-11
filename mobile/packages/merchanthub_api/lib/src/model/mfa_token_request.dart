//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mfa_token_request.g.dart';

/// MfaTokenRequest
///
/// Properties:
/// * [mfaToken] 
@BuiltValue()
abstract class MfaTokenRequest implements Built<MfaTokenRequest, MfaTokenRequestBuilder> {
  @BuiltValueField(wireName: r'mfa_token')
  String get mfaToken;

  MfaTokenRequest._();

  factory MfaTokenRequest([void updates(MfaTokenRequestBuilder b)]) = _$MfaTokenRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MfaTokenRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MfaTokenRequest> get serializer => _$MfaTokenRequestSerializer();
}

class _$MfaTokenRequestSerializer implements PrimitiveSerializer<MfaTokenRequest> {
  @override
  final Iterable<Type> types = const [MfaTokenRequest, _$MfaTokenRequest];

  @override
  final String wireName = r'MfaTokenRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MfaTokenRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mfa_token';
    yield serializers.serialize(
      object.mfaToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MfaTokenRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MfaTokenRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MfaTokenRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MfaTokenRequestBuilder();
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

