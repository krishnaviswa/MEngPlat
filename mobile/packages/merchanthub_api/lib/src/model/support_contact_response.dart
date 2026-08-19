//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'support_contact_response.g.dart';

/// SupportContactResponse
///
/// Properties:
/// * [email] 
/// * [supportPath] 
@BuiltValue()
abstract class SupportContactResponse implements Built<SupportContactResponse, SupportContactResponseBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'support_path')
  String? get supportPath;

  SupportContactResponse._();

  factory SupportContactResponse([void updates(SupportContactResponseBuilder b)]) = _$SupportContactResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SupportContactResponseBuilder b) => b
      ..supportPath = '/support';

  @BuiltValueSerializer(custom: true)
  static Serializer<SupportContactResponse> get serializer => _$SupportContactResponseSerializer();
}

class _$SupportContactResponseSerializer implements PrimitiveSerializer<SupportContactResponse> {
  @override
  final Iterable<Type> types = const [SupportContactResponse, _$SupportContactResponse];

  @override
  final String wireName = r'SupportContactResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SupportContactResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    if (object.supportPath != null) {
      yield r'support_path';
      yield serializers.serialize(
        object.supportPath,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SupportContactResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SupportContactResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'support_path':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.supportPath = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SupportContactResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SupportContactResponseBuilder();
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

