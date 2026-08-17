//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_whats_app_draft_approve_request.g.dart';

/// Optional admin-edited field values; omitted keys fall back to the AI extraction (S-053).
///
/// Properties:
/// * [fields] 
@BuiltValue()
abstract class AdminWhatsAppDraftApproveRequest implements Built<AdminWhatsAppDraftApproveRequest, AdminWhatsAppDraftApproveRequestBuilder> {
  @BuiltValueField(wireName: r'fields')
  JsonObject? get fields;

  AdminWhatsAppDraftApproveRequest._();

  factory AdminWhatsAppDraftApproveRequest([void updates(AdminWhatsAppDraftApproveRequestBuilder b)]) = _$AdminWhatsAppDraftApproveRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminWhatsAppDraftApproveRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminWhatsAppDraftApproveRequest> get serializer => _$AdminWhatsAppDraftApproveRequestSerializer();
}

class _$AdminWhatsAppDraftApproveRequestSerializer implements PrimitiveSerializer<AdminWhatsAppDraftApproveRequest> {
  @override
  final Iterable<Type> types = const [AdminWhatsAppDraftApproveRequest, _$AdminWhatsAppDraftApproveRequest];

  @override
  final String wireName = r'AdminWhatsAppDraftApproveRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminWhatsAppDraftApproveRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.fields != null) {
      yield r'fields';
      yield serializers.serialize(
        object.fields,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminWhatsAppDraftApproveRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminWhatsAppDraftApproveRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fields':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.fields = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminWhatsAppDraftApproveRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminWhatsAppDraftApproveRequestBuilder();
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

