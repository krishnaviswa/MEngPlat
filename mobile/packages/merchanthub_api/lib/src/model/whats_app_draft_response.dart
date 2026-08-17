//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/draft_status.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'whats_app_draft_response.g.dart';

/// WhatsAppDraftResponse
///
/// Properties:
/// * [id] 
/// * [source_] 
/// * [extractedFields] 
/// * [status] 
/// * [degraded] 
/// * [createdAt] 
@BuiltValue()
abstract class WhatsAppDraftResponse implements Built<WhatsAppDraftResponse, WhatsAppDraftResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'source')
  String get source_;

  @BuiltValueField(wireName: r'extracted_fields')
  JsonObject get extractedFields;

  @BuiltValueField(wireName: r'status')
  DraftStatus get status;
  // enum statusEnum {  pending,  applied,  discarded,  };

  @BuiltValueField(wireName: r'degraded')
  bool? get degraded;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  WhatsAppDraftResponse._();

  factory WhatsAppDraftResponse([void updates(WhatsAppDraftResponseBuilder b)]) = _$WhatsAppDraftResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WhatsAppDraftResponseBuilder b) => b
      ..degraded = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<WhatsAppDraftResponse> get serializer => _$WhatsAppDraftResponseSerializer();
}

class _$WhatsAppDraftResponseSerializer implements PrimitiveSerializer<WhatsAppDraftResponse> {
  @override
  final Iterable<Type> types = const [WhatsAppDraftResponse, _$WhatsAppDraftResponse];

  @override
  final String wireName = r'WhatsAppDraftResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WhatsAppDraftResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(String),
    );
    yield r'extracted_fields';
    yield serializers.serialize(
      object.extractedFields,
      specifiedType: const FullType(JsonObject),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DraftStatus),
    );
    if (object.degraded != null) {
      yield r'degraded';
      yield serializers.serialize(
        object.degraded,
        specifiedType: const FullType(bool),
      );
    }
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    WhatsAppDraftResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WhatsAppDraftResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.source_ = valueDes;
          break;
        case r'extracted_fields':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.extractedFields = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DraftStatus),
          ) as DraftStatus;
          result.status = valueDes;
          break;
        case r'degraded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.degraded = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WhatsAppDraftResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WhatsAppDraftResponseBuilder();
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

