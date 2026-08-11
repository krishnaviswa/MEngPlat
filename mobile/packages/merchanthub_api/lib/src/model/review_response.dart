//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:merchanthub_api/src/model/ai_analysis_response.dart';
import 'package:merchanthub_api/src/model/review_status.dart';
import 'package:merchanthub_api/src/model/reply_response.dart';
import 'package:merchanthub_api/src/model/user_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_response.g.dart';

/// ReviewResponse
///
/// Properties:
/// * [id] 
/// * [businessId] 
/// * [authorId] 
/// * [rating] 
/// * [title] 
/// * [body] 
/// * [status] 
/// * [likeCount] 
/// * [createdAt] 
/// * [author] 
/// * [aiAnalysis] 
/// * [reply] 
/// * [photoUrls] 
@BuiltValue()
abstract class ReviewResponse implements Built<ReviewResponse, ReviewResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'author_id')
  String get authorId;

  @BuiltValueField(wireName: r'rating')
  int get rating;

  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'body')
  String get body;

  @BuiltValueField(wireName: r'status')
  ReviewStatus get status;
  // enum statusEnum {  active,  hidden,  reported,  removed,  };

  @BuiltValueField(wireName: r'like_count')
  int get likeCount;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'author')
  UserResponse? get author;

  @BuiltValueField(wireName: r'ai_analysis')
  AIAnalysisResponse? get aiAnalysis;

  @BuiltValueField(wireName: r'reply')
  ReplyResponse? get reply;

  @BuiltValueField(wireName: r'photo_urls')
  BuiltList<String>? get photoUrls;

  ReviewResponse._();

  factory ReviewResponse([void updates(ReviewResponseBuilder b)]) = _$ReviewResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReviewResponseBuilder b) => b
      ..photoUrls = ListBuilder();

  @BuiltValueSerializer(custom: true)
  static Serializer<ReviewResponse> get serializer => _$ReviewResponseSerializer();
}

class _$ReviewResponseSerializer implements PrimitiveSerializer<ReviewResponse> {
  @override
  final Iterable<Type> types = const [ReviewResponse, _$ReviewResponse];

  @override
  final String wireName = r'ReviewResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReviewResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    yield r'author_id';
    yield serializers.serialize(
      object.authorId,
      specifiedType: const FullType(String),
    );
    yield r'rating';
    yield serializers.serialize(
      object.rating,
      specifiedType: const FullType(int),
    );
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'body';
    yield serializers.serialize(
      object.body,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ReviewStatus),
    );
    yield r'like_count';
    yield serializers.serialize(
      object.likeCount,
      specifiedType: const FullType(int),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.author != null) {
      yield r'author';
      yield serializers.serialize(
        object.author,
        specifiedType: const FullType(UserResponse),
      );
    }
    if (object.aiAnalysis != null) {
      yield r'ai_analysis';
      yield serializers.serialize(
        object.aiAnalysis,
        specifiedType: const FullType(AIAnalysisResponse),
      );
    }
    if (object.reply != null) {
      yield r'reply';
      yield serializers.serialize(
        object.reply,
        specifiedType: const FullType(ReplyResponse),
      );
    }
    if (object.photoUrls != null) {
      yield r'photo_urls';
      yield serializers.serialize(
        object.photoUrls,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ReviewResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReviewResponseBuilder result,
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
        case r'business_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.businessId = valueDes;
          break;
        case r'author_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.authorId = valueDes;
          break;
        case r'rating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.rating = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.title = valueDes;
          break;
        case r'body':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.body = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReviewStatus),
          ) as ReviewStatus;
          result.status = valueDes;
          break;
        case r'like_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.likeCount = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'author':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserResponse),
          ) as UserResponse;
          result.author.replace(valueDes);
          break;
        case r'ai_analysis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AIAnalysisResponse),
          ) as AIAnalysisResponse;
          result.aiAnalysis.replace(valueDes);
          break;
        case r'reply':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReplyResponse),
          ) as ReplyResponse;
          result.reply.replace(valueDes);
          break;
        case r'photo_urls':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.photoUrls.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReviewResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReviewResponseBuilder();
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

