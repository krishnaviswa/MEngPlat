//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'whats_app_webhook_ack.g.dart';

/// WhatsAppWebhookAck
///
/// Properties:
/// * [ok] 
/// * [processed] 
@BuiltValue()
abstract class WhatsAppWebhookAck implements Built<WhatsAppWebhookAck, WhatsAppWebhookAckBuilder> {
  @BuiltValueField(wireName: r'ok')
  bool? get ok;

  @BuiltValueField(wireName: r'processed')
  int? get processed;

  WhatsAppWebhookAck._();

  factory WhatsAppWebhookAck([void updates(WhatsAppWebhookAckBuilder b)]) = _$WhatsAppWebhookAck;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WhatsAppWebhookAckBuilder b) => b
      ..ok = true
      ..processed = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<WhatsAppWebhookAck> get serializer => _$WhatsAppWebhookAckSerializer();
}

class _$WhatsAppWebhookAckSerializer implements PrimitiveSerializer<WhatsAppWebhookAck> {
  @override
  final Iterable<Type> types = const [WhatsAppWebhookAck, _$WhatsAppWebhookAck];

  @override
  final String wireName = r'WhatsAppWebhookAck';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WhatsAppWebhookAck object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.ok != null) {
      yield r'ok';
      yield serializers.serialize(
        object.ok,
        specifiedType: const FullType(bool),
      );
    }
    if (object.processed != null) {
      yield r'processed';
      yield serializers.serialize(
        object.processed,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WhatsAppWebhookAck object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WhatsAppWebhookAckBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ok':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ok = valueDes;
          break;
        case r'processed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.processed = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WhatsAppWebhookAck deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WhatsAppWebhookAckBuilder();
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

