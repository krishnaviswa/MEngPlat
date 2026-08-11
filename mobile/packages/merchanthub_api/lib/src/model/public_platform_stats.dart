//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'public_platform_stats.g.dart';

/// Public home-page counts — deliberately excludes admin-only fields.
///
/// Properties:
/// * [totalBusinesses] 
/// * [totalReviews] 
/// * [totalCategories] 
/// * [totalCities] 
@BuiltValue()
abstract class PublicPlatformStats implements Built<PublicPlatformStats, PublicPlatformStatsBuilder> {
  @BuiltValueField(wireName: r'total_businesses')
  int get totalBusinesses;

  @BuiltValueField(wireName: r'total_reviews')
  int get totalReviews;

  @BuiltValueField(wireName: r'total_categories')
  int get totalCategories;

  @BuiltValueField(wireName: r'total_cities')
  int get totalCities;

  PublicPlatformStats._();

  factory PublicPlatformStats([void updates(PublicPlatformStatsBuilder b)]) = _$PublicPlatformStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PublicPlatformStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PublicPlatformStats> get serializer => _$PublicPlatformStatsSerializer();
}

class _$PublicPlatformStatsSerializer implements PrimitiveSerializer<PublicPlatformStats> {
  @override
  final Iterable<Type> types = const [PublicPlatformStats, _$PublicPlatformStats];

  @override
  final String wireName = r'PublicPlatformStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PublicPlatformStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total_businesses';
    yield serializers.serialize(
      object.totalBusinesses,
      specifiedType: const FullType(int),
    );
    yield r'total_reviews';
    yield serializers.serialize(
      object.totalReviews,
      specifiedType: const FullType(int),
    );
    yield r'total_categories';
    yield serializers.serialize(
      object.totalCategories,
      specifiedType: const FullType(int),
    );
    yield r'total_cities';
    yield serializers.serialize(
      object.totalCities,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PublicPlatformStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PublicPlatformStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total_businesses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalBusinesses = valueDes;
          break;
        case r'total_reviews':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalReviews = valueDes;
          break;
        case r'total_categories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalCategories = valueDes;
          break;
        case r'total_cities':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalCities = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PublicPlatformStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PublicPlatformStatsBuilder();
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

