//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'whats_app_link_response.g.dart';

/// WhatsAppLinkResponse
///
/// Properties:
/// * [available] 
/// * [waUrl] 
/// * [token] 
/// * [expiresAt] 
/// * [displayNumber] 
@BuiltValue()
abstract class WhatsAppLinkResponse implements Built<WhatsAppLinkResponse, WhatsAppLinkResponseBuilder> {
  @BuiltValueField(wireName: r'available')
  bool get available;

  @BuiltValueField(wireName: r'wa_url')
  String? get waUrl;

  @BuiltValueField(wireName: r'token')
  String? get token;

  @BuiltValueField(wireName: r'expires_at')
  DateTime? get expiresAt;

  @BuiltValueField(wireName: r'display_number')
  String? get displayNumber;

  WhatsAppLinkResponse._();

  factory WhatsAppLinkResponse([void updates(WhatsAppLinkResponseBuilder b)]) = _$WhatsAppLinkResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WhatsAppLinkResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WhatsAppLinkResponse> get serializer => _$WhatsAppLinkResponseSerializer();
}

class _$WhatsAppLinkResponseSerializer implements PrimitiveSerializer<WhatsAppLinkResponse> {
  @override
  final Iterable<Type> types = const [WhatsAppLinkResponse, _$WhatsAppLinkResponse];

  @override
  final String wireName = r'WhatsAppLinkResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WhatsAppLinkResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'available';
    yield serializers.serialize(
      object.available,
      specifiedType: const FullType(bool),
    );
    if (object.waUrl != null) {
      yield r'wa_url';
      yield serializers.serialize(
        object.waUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.token != null) {
      yield r'token';
      yield serializers.serialize(
        object.token,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.expiresAt != null) {
      yield r'expires_at';
      yield serializers.serialize(
        object.expiresAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.displayNumber != null) {
      yield r'display_number';
      yield serializers.serialize(
        object.displayNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WhatsAppLinkResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WhatsAppLinkResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'available':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.available = valueDes;
          break;
        case r'wa_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.waUrl = valueDes;
          break;
        case r'token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.token = valueDes;
          break;
        case r'expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.expiresAt = valueDes;
          break;
        case r'display_number':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.displayNumber = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WhatsAppLinkResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WhatsAppLinkResponseBuilder();
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

