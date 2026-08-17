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
/// * [ratingDistribution] 
/// * [replyRate] 
/// * [reviewCountInRange] 
/// * [reviewCountPrevious] 
/// * [replyRatePrevious] 
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

  @BuiltValueField(wireName: r'rating_distribution')
  BuiltMap<String, int> get ratingDistribution;

  @BuiltValueField(wireName: r'reply_rate')
  num? get replyRate;

  @BuiltValueField(wireName: r'review_count_in_range')
  int? get reviewCountInRange;

  @BuiltValueField(wireName: r'review_count_previous')
  int? get reviewCountPrevious;

  @BuiltValueField(wireName: r'reply_rate_previous')
  num? get replyRatePrevious;

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
    yield r'rating_distribution';
    yield serializers.serialize(
      object.ratingDistribution,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
    );
    if (object.replyRate != null) {
      yield r'reply_rate';
      yield serializers.serialize(
        object.replyRate,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.reviewCountInRange != null) {
      yield r'review_count_in_range';
      yield serializers.serialize(
        object.reviewCountInRange,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.reviewCountPrevious != null) {
      yield r'review_count_previous';
      yield serializers.serialize(
        object.reviewCountPrevious,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.replyRatePrevious != null) {
      yield r'reply_rate_previous';
      yield serializers.serialize(
        object.replyRatePrevious,
        specifiedType: const FullType.nullable(num),
      );
    }
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
        case r'rating_distribution':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
          ) as BuiltMap<String, int>;
          result.ratingDistribution.replace(valueDes);
          break;
        case r'reply_rate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.replyRate = valueDes;
          break;
        case r'review_count_in_range':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.reviewCountInRange = valueDes;
          break;
        case r'review_count_previous':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.reviewCountPrevious = valueDes;
          break;
        case r'reply_rate_previous':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.replyRatePrevious = valueDes;
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

