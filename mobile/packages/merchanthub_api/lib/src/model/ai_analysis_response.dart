//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/sentiment.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ai_analysis_response.g.dart';

/// AIAnalysisResponse
///
/// Properties:
/// * [id] 
/// * [analysisType] 
/// * [sentiment] 
/// * [summary] 
/// * [positives] 
/// * [complaints] 
/// * [suggestedResponse] 
/// * [imageInsights] 
/// * [provider] 
/// * [degraded] 
@BuiltValue()
abstract class AIAnalysisResponse implements Built<AIAnalysisResponse, AIAnalysisResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'analysis_type')
  String get analysisType;

  @BuiltValueField(wireName: r'sentiment')
  Sentiment? get sentiment;
  // enum sentimentEnum {  positive,  neutral,  negative,  };

  @BuiltValueField(wireName: r'summary')
  String? get summary;

  @BuiltValueField(wireName: r'positives')
  BuiltList<String>? get positives;

  @BuiltValueField(wireName: r'complaints')
  BuiltList<String>? get complaints;

  @BuiltValueField(wireName: r'suggested_response')
  String? get suggestedResponse;

  @BuiltValueField(wireName: r'image_insights')
  JsonObject? get imageInsights;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'degraded')
  bool? get degraded;

  AIAnalysisResponse._();

  factory AIAnalysisResponse([void updates(AIAnalysisResponseBuilder b)]) = _$AIAnalysisResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AIAnalysisResponseBuilder b) => b
      ..degraded = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<AIAnalysisResponse> get serializer => _$AIAnalysisResponseSerializer();
}

class _$AIAnalysisResponseSerializer implements PrimitiveSerializer<AIAnalysisResponse> {
  @override
  final Iterable<Type> types = const [AIAnalysisResponse, _$AIAnalysisResponse];

  @override
  final String wireName = r'AIAnalysisResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AIAnalysisResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'analysis_type';
    yield serializers.serialize(
      object.analysisType,
      specifiedType: const FullType(String),
    );
    if (object.sentiment != null) {
      yield r'sentiment';
      yield serializers.serialize(
        object.sentiment,
        specifiedType: const FullType(Sentiment),
      );
    }
    if (object.summary != null) {
      yield r'summary';
      yield serializers.serialize(
        object.summary,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.positives != null) {
      yield r'positives';
      yield serializers.serialize(
        object.positives,
        specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
      );
    }
    if (object.complaints != null) {
      yield r'complaints';
      yield serializers.serialize(
        object.complaints,
        specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
      );
    }
    if (object.suggestedResponse != null) {
      yield r'suggested_response';
      yield serializers.serialize(
        object.suggestedResponse,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.imageInsights != null) {
      yield r'image_insights';
      yield serializers.serialize(
        object.imageInsights,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
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
    AIAnalysisResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AIAnalysisResponseBuilder result,
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
        case r'analysis_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.analysisType = valueDes;
          break;
        case r'sentiment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Sentiment),
          ) as Sentiment;
          result.sentiment = valueDes;
          break;
        case r'summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.summary = valueDes;
          break;
        case r'positives':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
          ) as BuiltList<String>?;
          if (valueDes == null) continue;
          result.positives.replace(valueDes);
          break;
        case r'complaints':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
          ) as BuiltList<String>?;
          if (valueDes == null) continue;
          result.complaints.replace(valueDes);
          break;
        case r'suggested_response':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.suggestedResponse = valueDes;
          break;
        case r'image_insights':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.imageInsights = valueDes;
          break;
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.provider = valueDes;
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
  AIAnalysisResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AIAnalysisResponseBuilder();
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

