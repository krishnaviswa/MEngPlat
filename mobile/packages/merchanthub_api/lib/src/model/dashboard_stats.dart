//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:merchanthub_api/src/model/review_response.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'dashboard_stats.g.dart';

/// DashboardStats
///
/// Properties:
/// * [totalReviews] 
/// * [averageRating] 
/// * [sentimentBreakdown] 
/// * [recentReviews] 
/// * [reviewVolumeByMonth] 
@BuiltValue()
abstract class DashboardStats implements Built<DashboardStats, DashboardStatsBuilder> {
  @BuiltValueField(wireName: r'total_reviews')
  int get totalReviews;

  @BuiltValueField(wireName: r'average_rating')
  num get averageRating;

  @BuiltValueField(wireName: r'sentiment_breakdown')
  BuiltMap<String, int> get sentimentBreakdown;

  @BuiltValueField(wireName: r'recent_reviews')
  BuiltList<ReviewResponse> get recentReviews;

  @BuiltValueField(wireName: r'review_volume_by_month')
  BuiltList<JsonObject> get reviewVolumeByMonth;

  DashboardStats._();

  factory DashboardStats([void updates(DashboardStatsBuilder b)]) = _$DashboardStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DashboardStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DashboardStats> get serializer => _$DashboardStatsSerializer();
}

class _$DashboardStatsSerializer implements PrimitiveSerializer<DashboardStats> {
  @override
  final Iterable<Type> types = const [DashboardStats, _$DashboardStats];

  @override
  final String wireName = r'DashboardStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DashboardStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total_reviews';
    yield serializers.serialize(
      object.totalReviews,
      specifiedType: const FullType(int),
    );
    yield r'average_rating';
    yield serializers.serialize(
      object.averageRating,
      specifiedType: const FullType(num),
    );
    yield r'sentiment_breakdown';
    yield serializers.serialize(
      object.sentimentBreakdown,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
    );
    yield r'recent_reviews';
    yield serializers.serialize(
      object.recentReviews,
      specifiedType: const FullType(BuiltList, [FullType(ReviewResponse)]),
    );
    yield r'review_volume_by_month';
    yield serializers.serialize(
      object.reviewVolumeByMonth,
      specifiedType: const FullType(BuiltList, [FullType(JsonObject)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DashboardStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DashboardStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total_reviews':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalReviews = valueDes;
          break;
        case r'average_rating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.averageRating = valueDes;
          break;
        case r'sentiment_breakdown':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
          ) as BuiltMap<String, int>;
          result.sentimentBreakdown.replace(valueDes);
          break;
        case r'recent_reviews':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ReviewResponse)]),
          ) as BuiltList<ReviewResponse>;
          result.recentReviews.replace(valueDes);
          break;
        case r'review_volume_by_month':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(JsonObject)]),
          ) as BuiltList<JsonObject>;
          result.reviewVolumeByMonth.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DashboardStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DashboardStatsBuilder();
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

