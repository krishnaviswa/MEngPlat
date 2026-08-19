//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'support_ticket_create.g.dart';

/// SupportTicketCreate
///
/// Properties:
/// * [name] 
/// * [phone] 
/// * [issue] 
/// * [businessId] 
@BuiltValue()
abstract class SupportTicketCreate implements Built<SupportTicketCreate, SupportTicketCreateBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'phone')
  String get phone;

  @BuiltValueField(wireName: r'issue')
  String get issue;

  @BuiltValueField(wireName: r'business_id')
  String? get businessId;

  SupportTicketCreate._();

  factory SupportTicketCreate([void updates(SupportTicketCreateBuilder b)]) = _$SupportTicketCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SupportTicketCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SupportTicketCreate> get serializer => _$SupportTicketCreateSerializer();
}

class _$SupportTicketCreateSerializer implements PrimitiveSerializer<SupportTicketCreate> {
  @override
  final Iterable<Type> types = const [SupportTicketCreate, _$SupportTicketCreate];

  @override
  final String wireName = r'SupportTicketCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SupportTicketCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'phone';
    yield serializers.serialize(
      object.phone,
      specifiedType: const FullType(String),
    );
    yield r'issue';
    yield serializers.serialize(
      object.issue,
      specifiedType: const FullType(String),
    );
    if (object.businessId != null) {
      yield r'business_id';
      yield serializers.serialize(
        object.businessId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SupportTicketCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SupportTicketCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.issue = valueDes;
          break;
        case r'business_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.businessId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SupportTicketCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SupportTicketCreateBuilder();
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

