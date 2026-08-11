//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'favorite_response.g.dart';

/// FavoriteResponse
///
/// Properties:
/// * [favorited] 
/// * [businessId] 
@BuiltValue()
abstract class FavoriteResponse implements Built<FavoriteResponse, FavoriteResponseBuilder> {
  @BuiltValueField(wireName: r'favorited')
  bool get favorited;

  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  FavoriteResponse._();

  factory FavoriteResponse([void updates(FavoriteResponseBuilder b)]) = _$FavoriteResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FavoriteResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FavoriteResponse> get serializer => _$FavoriteResponseSerializer();
}

class _$FavoriteResponseSerializer implements PrimitiveSerializer<FavoriteResponse> {
  @override
  final Iterable<Type> types = const [FavoriteResponse, _$FavoriteResponse];

  @override
  final String wireName = r'FavoriteResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FavoriteResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'favorited';
    yield serializers.serialize(
      object.favorited,
      specifiedType: const FullType(bool),
    );
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FavoriteResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FavoriteResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'favorited':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.favorited = valueDes;
          break;
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
  FavoriteResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FavoriteResponseBuilder();
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

