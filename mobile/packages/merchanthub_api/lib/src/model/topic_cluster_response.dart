//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/topic_item.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'topic_cluster_response.g.dart';

/// TopicClusterResponse
///
/// Properties:
/// * [businessId] 
/// * [topics] 
/// * [degraded] 
/// * [insufficientData] 
/// * [unavailable] 
@BuiltValue()
abstract class TopicClusterResponse implements Built<TopicClusterResponse, TopicClusterResponseBuilder> {
  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'topics')
  BuiltList<TopicItem>? get topics;

  @BuiltValueField(wireName: r'degraded')
  bool? get degraded;

  @BuiltValueField(wireName: r'insufficient_data')
  bool? get insufficientData;

  @BuiltValueField(wireName: r'unavailable')
  bool? get unavailable;

  TopicClusterResponse._();

  factory TopicClusterResponse([void updates(TopicClusterResponseBuilder b)]) = _$TopicClusterResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TopicClusterResponseBuilder b) => b
      ..topics = ListBuilder()
      ..degraded = false
      ..insufficientData = false
      ..unavailable = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<TopicClusterResponse> get serializer => _$TopicClusterResponseSerializer();
}

class _$TopicClusterResponseSerializer implements PrimitiveSerializer<TopicClusterResponse> {
  @override
  final Iterable<Type> types = const [TopicClusterResponse, _$TopicClusterResponse];

  @override
  final String wireName = r'TopicClusterResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TopicClusterResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    if (object.topics != null) {
      yield r'topics';
      yield serializers.serialize(
        object.topics,
        specifiedType: const FullType(BuiltList, [FullType(TopicItem)]),
      );
    }
    if (object.degraded != null) {
      yield r'degraded';
      yield serializers.serialize(
        object.degraded,
        specifiedType: const FullType(bool),
      );
    }
    if (object.insufficientData != null) {
      yield r'insufficient_data';
      yield serializers.serialize(
        object.insufficientData,
        specifiedType: const FullType(bool),
      );
    }
    if (object.unavailable != null) {
      yield r'unavailable';
      yield serializers.serialize(
        object.unavailable,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TopicClusterResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TopicClusterResponseBuilder result,
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
        case r'topics':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TopicItem)]),
          ) as BuiltList<TopicItem>;
          result.topics.replace(valueDes);
          break;
        case r'degraded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.degraded = valueDes;
          break;
        case r'insufficient_data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.insufficientData = valueDes;
          break;
        case r'unavailable':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.unavailable = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TopicClusterResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TopicClusterResponseBuilder();
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

