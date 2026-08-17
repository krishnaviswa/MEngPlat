//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'placement_window.g.dart';

/// PlacementWindow
///
/// Properties:
/// * [id] 
/// * [startsAt] 
/// * [endsAt] 
/// * [disabledAt] 
/// * [paymentId] 
@BuiltValue()
abstract class PlacementWindow implements Built<PlacementWindow, PlacementWindowBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'starts_at')
  DateTime get startsAt;

  @BuiltValueField(wireName: r'ends_at')
  DateTime get endsAt;

  @BuiltValueField(wireName: r'disabled_at')
  DateTime? get disabledAt;

  @BuiltValueField(wireName: r'payment_id')
  String get paymentId;

  PlacementWindow._();

  factory PlacementWindow([void updates(PlacementWindowBuilder b)]) = _$PlacementWindow;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlacementWindowBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlacementWindow> get serializer => _$PlacementWindowSerializer();
}

class _$PlacementWindowSerializer implements PrimitiveSerializer<PlacementWindow> {
  @override
  final Iterable<Type> types = const [PlacementWindow, _$PlacementWindow];

  @override
  final String wireName = r'PlacementWindow';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlacementWindow object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'starts_at';
    yield serializers.serialize(
      object.startsAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'ends_at';
    yield serializers.serialize(
      object.endsAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.disabledAt != null) {
      yield r'disabled_at';
      yield serializers.serialize(
        object.disabledAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'payment_id';
    yield serializers.serialize(
      object.paymentId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlacementWindow object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlacementWindowBuilder result,
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
        case r'starts_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startsAt = valueDes;
          break;
        case r'ends_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.endsAt = valueDes;
          break;
        case r'disabled_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.disabledAt = valueDes;
          break;
        case r'payment_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.paymentId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlacementWindow deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlacementWindowBuilder();
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

