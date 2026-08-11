//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'merchant_insights_response.g.dart';

/// MerchantInsightsResponse
///
/// Properties:
/// * [businessId] 
/// * [merchantSummary] 
/// * [frequentlyMentionedPositives] 
/// * [frequentlyMentionedComplaints] 
/// * [suggestedResponses] 
/// * [monthlyTrends] 
/// * [sentimentBreakdown] 
/// * [degraded] 
@BuiltValue()
abstract class MerchantInsightsResponse implements Built<MerchantInsightsResponse, MerchantInsightsResponseBuilder> {
  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'merchant_summary')
  String? get merchantSummary;

  @BuiltValueField(wireName: r'frequently_mentioned_positives')
  BuiltList<String> get frequentlyMentionedPositives;

  @BuiltValueField(wireName: r'frequently_mentioned_complaints')
  BuiltList<String> get frequentlyMentionedComplaints;

  @BuiltValueField(wireName: r'suggested_responses')
  BuiltList<String> get suggestedResponses;

  @BuiltValueField(wireName: r'monthly_trends')
  BuiltList<JsonObject> get monthlyTrends;

  @BuiltValueField(wireName: r'sentiment_breakdown')
  BuiltMap<String, int> get sentimentBreakdown;

  @BuiltValueField(wireName: r'degraded')
  bool? get degraded;

  MerchantInsightsResponse._();

  factory MerchantInsightsResponse([void updates(MerchantInsightsResponseBuilder b)]) = _$MerchantInsightsResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MerchantInsightsResponseBuilder b) => b
      ..degraded = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<MerchantInsightsResponse> get serializer => _$MerchantInsightsResponseSerializer();
}

class _$MerchantInsightsResponseSerializer implements PrimitiveSerializer<MerchantInsightsResponse> {
  @override
  final Iterable<Type> types = const [MerchantInsightsResponse, _$MerchantInsightsResponse];

  @override
  final String wireName = r'MerchantInsightsResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MerchantInsightsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    yield r'merchant_summary';
    yield object.merchantSummary == null ? null : serializers.serialize(
      object.merchantSummary,
      specifiedType: const FullType.nullable(String),
    );
    yield r'frequently_mentioned_positives';
    yield serializers.serialize(
      object.frequentlyMentionedPositives,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'frequently_mentioned_complaints';
    yield serializers.serialize(
      object.frequentlyMentionedComplaints,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'suggested_responses';
    yield serializers.serialize(
      object.suggestedResponses,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'monthly_trends';
    yield serializers.serialize(
      object.monthlyTrends,
      specifiedType: const FullType(BuiltList, [FullType(JsonObject)]),
    );
    yield r'sentiment_breakdown';
    yield serializers.serialize(
      object.sentimentBreakdown,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
    );
    if (object.degraded != null) {
      yield r'degraded';
      yield serializers.serialize(
        object.degraded,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MerchantInsightsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MerchantInsightsResponseBuilder result,
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
        case r'merchant_summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.merchantSummary = valueDes;
          break;
        case r'frequently_mentioned_positives':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.frequentlyMentionedPositives.replace(valueDes);
          break;
        case r'frequently_mentioned_complaints':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.frequentlyMentionedComplaints.replace(valueDes);
          break;
        case r'suggested_responses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.suggestedResponses.replace(valueDes);
          break;
        case r'monthly_trends':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(JsonObject)]),
          ) as BuiltList<JsonObject>;
          result.monthlyTrends.replace(valueDes);
          break;
        case r'sentiment_breakdown':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(int)]),
          ) as BuiltMap<String, int>;
          result.sentimentBreakdown.replace(valueDes);
          break;
        case r'degraded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.degraded = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MerchantInsightsResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MerchantInsightsResponseBuilder();
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

