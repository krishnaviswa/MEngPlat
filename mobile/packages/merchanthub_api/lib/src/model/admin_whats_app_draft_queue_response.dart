//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/admin_whats_app_draft_response.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_whats_app_draft_queue_response.g.dart';

/// AdminWhatsAppDraftQueueResponse
///
/// Properties:
/// * [items] 
/// * [total] 
/// * [page] 
/// * [pageSize] 
@BuiltValue()
abstract class AdminWhatsAppDraftQueueResponse implements Built<AdminWhatsAppDraftQueueResponse, AdminWhatsAppDraftQueueResponseBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<AdminWhatsAppDraftResponse> get items;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'page')
  int get page;

  @BuiltValueField(wireName: r'page_size')
  int get pageSize;

  AdminWhatsAppDraftQueueResponse._();

  factory AdminWhatsAppDraftQueueResponse([void updates(AdminWhatsAppDraftQueueResponseBuilder b)]) = _$AdminWhatsAppDraftQueueResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminWhatsAppDraftQueueResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminWhatsAppDraftQueueResponse> get serializer => _$AdminWhatsAppDraftQueueResponseSerializer();
}

class _$AdminWhatsAppDraftQueueResponseSerializer implements PrimitiveSerializer<AdminWhatsAppDraftQueueResponse> {
  @override
  final Iterable<Type> types = const [AdminWhatsAppDraftQueueResponse, _$AdminWhatsAppDraftQueueResponse];

  @override
  final String wireName = r'AdminWhatsAppDraftQueueResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminWhatsAppDraftQueueResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(AdminWhatsAppDraftResponse)]),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(int),
    );
    yield r'page_size';
    yield serializers.serialize(
      object.pageSize,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminWhatsAppDraftQueueResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminWhatsAppDraftQueueResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AdminWhatsAppDraftResponse)]),
          ) as BuiltList<AdminWhatsAppDraftResponse>;
          result.items.replace(valueDes);
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.page = valueDes;
          break;
        case r'page_size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.pageSize = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminWhatsAppDraftQueueResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminWhatsAppDraftQueueResponseBuilder();
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

