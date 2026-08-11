//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'totp_setup_response.g.dart';

/// TotpSetupResponse
///
/// Properties:
/// * [otpauthUri] 
/// * [secret] 
/// * [qrSvg] 
@BuiltValue()
abstract class TotpSetupResponse implements Built<TotpSetupResponse, TotpSetupResponseBuilder> {
  @BuiltValueField(wireName: r'otpauth_uri')
  String get otpauthUri;

  @BuiltValueField(wireName: r'secret')
  String get secret;

  @BuiltValueField(wireName: r'qr_svg')
  String get qrSvg;

  TotpSetupResponse._();

  factory TotpSetupResponse([void updates(TotpSetupResponseBuilder b)]) = _$TotpSetupResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TotpSetupResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TotpSetupResponse> get serializer => _$TotpSetupResponseSerializer();
}

class _$TotpSetupResponseSerializer implements PrimitiveSerializer<TotpSetupResponse> {
  @override
  final Iterable<Type> types = const [TotpSetupResponse, _$TotpSetupResponse];

  @override
  final String wireName = r'TotpSetupResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TotpSetupResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'otpauth_uri';
    yield serializers.serialize(
      object.otpauthUri,
      specifiedType: const FullType(String),
    );
    yield r'secret';
    yield serializers.serialize(
      object.secret,
      specifiedType: const FullType(String),
    );
    yield r'qr_svg';
    yield serializers.serialize(
      object.qrSvg,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TotpSetupResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TotpSetupResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'otpauth_uri':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.otpauthUri = valueDes;
          break;
        case r'secret':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.secret = valueDes;
          break;
        case r'qr_svg':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.qrSvg = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TotpSetupResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TotpSetupResponseBuilder();
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

