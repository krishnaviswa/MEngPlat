//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'support_ticket_admin_update.g.dart';

/// SupportTicketAdminUpdate
///
/// Properties:
/// * [status] 
/// * [adminResponse] 
@BuiltValue()
abstract class SupportTicketAdminUpdate implements Built<SupportTicketAdminUpdate, SupportTicketAdminUpdateBuilder> {
  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'admin_response')
  String? get adminResponse;

  SupportTicketAdminUpdate._();

  factory SupportTicketAdminUpdate([void updates(SupportTicketAdminUpdateBuilder b)]) = _$SupportTicketAdminUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SupportTicketAdminUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SupportTicketAdminUpdate> get serializer => _$SupportTicketAdminUpdateSerializer();
}

class _$SupportTicketAdminUpdateSerializer implements PrimitiveSerializer<SupportTicketAdminUpdate> {
  @override
  final Iterable<Type> types = const [SupportTicketAdminUpdate, _$SupportTicketAdminUpdate];

  @override
  final String wireName = r'SupportTicketAdminUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SupportTicketAdminUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.adminResponse != null) {
      yield r'admin_response';
      yield serializers.serialize(
        object.adminResponse,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SupportTicketAdminUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SupportTicketAdminUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'admin_response':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.adminResponse = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SupportTicketAdminUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SupportTicketAdminUpdateBuilder();
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

