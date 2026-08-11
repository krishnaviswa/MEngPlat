//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'platform_analytics.g.dart';

/// PlatformAnalytics
///
/// Properties:
/// * [totalUsers] 
/// * [totalBusinesses] 
/// * [pendingBusinesses] 
/// * [totalReviews] 
/// * [reportedReviews] 
@BuiltValue()
abstract class PlatformAnalytics implements Built<PlatformAnalytics, PlatformAnalyticsBuilder> {
  @BuiltValueField(wireName: r'total_users')
  int get totalUsers;

  @BuiltValueField(wireName: r'total_businesses')
  int get totalBusinesses;

  @BuiltValueField(wireName: r'pending_businesses')
  int get pendingBusinesses;

  @BuiltValueField(wireName: r'total_reviews')
  int get totalReviews;

  @BuiltValueField(wireName: r'reported_reviews')
  int get reportedReviews;

  PlatformAnalytics._();

  factory PlatformAnalytics([void updates(PlatformAnalyticsBuilder b)]) = _$PlatformAnalytics;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlatformAnalyticsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlatformAnalytics> get serializer => _$PlatformAnalyticsSerializer();
}

class _$PlatformAnalyticsSerializer implements PrimitiveSerializer<PlatformAnalytics> {
  @override
  final Iterable<Type> types = const [PlatformAnalytics, _$PlatformAnalytics];

  @override
  final String wireName = r'PlatformAnalytics';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlatformAnalytics object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total_users';
    yield serializers.serialize(
      object.totalUsers,
      specifiedType: const FullType(int),
    );
    yield r'total_businesses';
    yield serializers.serialize(
      object.totalBusinesses,
      specifiedType: const FullType(int),
    );
    yield r'pending_businesses';
    yield serializers.serialize(
      object.pendingBusinesses,
      specifiedType: const FullType(int),
    );
    yield r'total_reviews';
    yield serializers.serialize(
      object.totalReviews,
      specifiedType: const FullType(int),
    );
    yield r'reported_reviews';
    yield serializers.serialize(
      object.reportedReviews,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlatformAnalytics object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlatformAnalyticsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total_users':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalUsers = valueDes;
          break;
        case r'total_businesses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalBusinesses = valueDes;
          break;
        case r'pending_businesses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.pendingBusinesses = valueDes;
          break;
        case r'total_reviews':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalReviews = valueDes;
          break;
        case r'reported_reviews':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.reportedReviews = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlatformAnalytics deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlatformAnalyticsBuilder();
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

