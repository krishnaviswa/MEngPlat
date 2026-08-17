//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'topic_item.g.dart';

/// TopicItem
///
/// Properties:
/// * [label] 
/// * [count] 
/// * [sentiment] 
/// * [exampleQuote] 
@BuiltValue()
abstract class TopicItem implements Built<TopicItem, TopicItemBuilder> {
  @BuiltValueField(wireName: r'label')
  String get label;

  @BuiltValueField(wireName: r'count')
  int get count;

  @BuiltValueField(wireName: r'sentiment')
  TopicItemSentimentEnum get sentiment;
  // enum sentimentEnum {  positive,  negative,  mixed,  };

  @BuiltValueField(wireName: r'example_quote')
  String get exampleQuote;

  TopicItem._();

  factory TopicItem([void updates(TopicItemBuilder b)]) = _$TopicItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TopicItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TopicItem> get serializer => _$TopicItemSerializer();
}

class _$TopicItemSerializer implements PrimitiveSerializer<TopicItem> {
  @override
  final Iterable<Type> types = const [TopicItem, _$TopicItem];

  @override
  final String wireName = r'TopicItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TopicItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'label';
    yield serializers.serialize(
      object.label,
      specifiedType: const FullType(String),
    );
    yield r'count';
    yield serializers.serialize(
      object.count,
      specifiedType: const FullType(int),
    );
    yield r'sentiment';
    yield serializers.serialize(
      object.sentiment,
      specifiedType: const FullType(TopicItemSentimentEnum),
    );
    yield r'example_quote';
    yield serializers.serialize(
      object.exampleQuote,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TopicItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TopicItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'label':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.label = valueDes;
          break;
        case r'count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.count = valueDes;
          break;
        case r'sentiment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TopicItemSentimentEnum),
          ) as TopicItemSentimentEnum;
          result.sentiment = valueDes;
          break;
        case r'example_quote':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.exampleQuote = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TopicItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TopicItemBuilder();
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

class TopicItemSentimentEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'positive')
  static const TopicItemSentimentEnum positive = _$topicItemSentimentEnum_positive;
  @BuiltValueEnumConst(wireName: r'negative')
  static const TopicItemSentimentEnum negative = _$topicItemSentimentEnum_negative;
  @BuiltValueEnumConst(wireName: r'mixed')
  static const TopicItemSentimentEnum mixed = _$topicItemSentimentEnum_mixed;

  static Serializer<TopicItemSentimentEnum> get serializer => _$topicItemSentimentEnumSerializer;

  const TopicItemSentimentEnum._(String name): super(name);

  static BuiltSet<TopicItemSentimentEnum> get values => _$topicItemSentimentEnumValues;
  static TopicItemSentimentEnum valueOf(String name) => _$topicItemSentimentEnumValueOf(name);
}

