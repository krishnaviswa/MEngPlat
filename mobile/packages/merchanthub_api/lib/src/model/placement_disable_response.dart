//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'placement_disable_response.g.dart';

/// PlacementDisableResponse
///
/// Properties:
/// * [id] 
/// * [disabledAt] 
@BuiltValue()
abstract class PlacementDisableResponse implements Built<PlacementDisableResponse, PlacementDisableResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'disabled_at')
  DateTime get disabledAt;

  PlacementDisableResponse._();

  factory PlacementDisableResponse([void updates(PlacementDisableResponseBuilder b)]) = _$PlacementDisableResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlacementDisableResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlacementDisableResponse> get serializer => _$PlacementDisableResponseSerializer();
}

class _$PlacementDisableResponseSerializer implements PrimitiveSerializer<PlacementDisableResponse> {
  @override
  final Iterable<Type> types = const [PlacementDisableResponse, _$PlacementDisableResponse];

  @override
  final String wireName = r'PlacementDisableResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlacementDisableResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'disabled_at';
    yield serializers.serialize(
      object.disabledAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlacementDisableResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlacementDisableResponseBuilder result,
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
        case r'disabled_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.disabledAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlacementDisableResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlacementDisableResponseBuilder();
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

