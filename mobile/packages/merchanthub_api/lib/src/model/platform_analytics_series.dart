//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'platform_analytics_series.g.dart';

/// PlatformAnalyticsSeries
///
/// Properties:
/// * [granularity] 
/// * [days] 
/// * [series] 
@BuiltValue()
abstract class PlatformAnalyticsSeries implements Built<PlatformAnalyticsSeries, PlatformAnalyticsSeriesBuilder> {
  @BuiltValueField(wireName: r'granularity')
  PlatformAnalyticsSeriesGranularityEnum get granularity;
  // enum granularityEnum {  day,  week,  };

  @BuiltValueField(wireName: r'days')
  int get days;

  @BuiltValueField(wireName: r'series')
  BuiltMap<String, BuiltList<JsonObject>> get series;

  PlatformAnalyticsSeries._();

  factory PlatformAnalyticsSeries([void updates(PlatformAnalyticsSeriesBuilder b)]) = _$PlatformAnalyticsSeries;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlatformAnalyticsSeriesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlatformAnalyticsSeries> get serializer => _$PlatformAnalyticsSeriesSerializer();
}

class _$PlatformAnalyticsSeriesSerializer implements PrimitiveSerializer<PlatformAnalyticsSeries> {
  @override
  final Iterable<Type> types = const [PlatformAnalyticsSeries, _$PlatformAnalyticsSeries];

  @override
  final String wireName = r'PlatformAnalyticsSeries';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlatformAnalyticsSeries object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'granularity';
    yield serializers.serialize(
      object.granularity,
      specifiedType: const FullType(PlatformAnalyticsSeriesGranularityEnum),
    );
    yield r'days';
    yield serializers.serialize(
      object.days,
      specifiedType: const FullType(int),
    );
    yield r'series';
    yield serializers.serialize(
      object.series,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType(BuiltList, [FullType(JsonObject)])]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlatformAnalyticsSeries object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlatformAnalyticsSeriesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'granularity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlatformAnalyticsSeriesGranularityEnum),
          ) as PlatformAnalyticsSeriesGranularityEnum;
          result.granularity = valueDes;
          break;
        case r'days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.days = valueDes;
          break;
        case r'series':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(BuiltList, [FullType(JsonObject)])]),
          ) as BuiltMap<String, BuiltList<JsonObject>>;
          result.series.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlatformAnalyticsSeries deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlatformAnalyticsSeriesBuilder();
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

class PlatformAnalyticsSeriesGranularityEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'day')
  static const PlatformAnalyticsSeriesGranularityEnum day = _$platformAnalyticsSeriesGranularityEnum_day;
  @BuiltValueEnumConst(wireName: r'week')
  static const PlatformAnalyticsSeriesGranularityEnum week = _$platformAnalyticsSeriesGranularityEnum_week;

  static Serializer<PlatformAnalyticsSeriesGranularityEnum> get serializer => _$platformAnalyticsSeriesGranularityEnumSerializer;

  const PlatformAnalyticsSeriesGranularityEnum._(String name): super(name);

  static BuiltSet<PlatformAnalyticsSeriesGranularityEnum> get values => _$platformAnalyticsSeriesGranularityEnumValues;
  static PlatformAnalyticsSeriesGranularityEnum valueOf(String name) => _$platformAnalyticsSeriesGranularityEnumValueOf(name);
}

