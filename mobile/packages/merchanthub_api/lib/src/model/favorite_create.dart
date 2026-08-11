//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'favorite_create.g.dart';

/// FavoriteCreate
///
/// Properties:
/// * [businessId] 
@BuiltValue()
abstract class FavoriteCreate implements Built<FavoriteCreate, FavoriteCreateBuilder> {
  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  FavoriteCreate._();

  factory FavoriteCreate([void updates(FavoriteCreateBuilder b)]) = _$FavoriteCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FavoriteCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FavoriteCreate> get serializer => _$FavoriteCreateSerializer();
}

class _$FavoriteCreateSerializer implements PrimitiveSerializer<FavoriteCreate> {
  @override
  final Iterable<Type> types = const [FavoriteCreate, _$FavoriteCreate];

  @override
  final String wireName = r'FavoriteCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FavoriteCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FavoriteCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FavoriteCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'business_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  FavoriteCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FavoriteCreateBuilder();
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

