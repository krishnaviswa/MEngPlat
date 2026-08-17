//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'external_review_response.g.dart';

/// ExternalReviewResponse
///
/// Properties:
/// * [id] 
/// * [authorName] 
/// * [authorPhotoUrl] 
/// * [rating] 
/// * [body] 
/// * [source_] 
/// * [sourceUrl] 
/// * [externalPostedAt] 
@BuiltValue()
abstract class ExternalReviewResponse implements Built<ExternalReviewResponse, ExternalReviewResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'author_name')
  String get authorName;

  @BuiltValueField(wireName: r'author_photo_url')
  String? get authorPhotoUrl;

  @BuiltValueField(wireName: r'rating')
  int get rating;

  @BuiltValueField(wireName: r'body')
  String? get body;

  @BuiltValueField(wireName: r'source')
  String get source_;

  @BuiltValueField(wireName: r'source_url')
  String? get sourceUrl;

  @BuiltValueField(wireName: r'external_posted_at')
  DateTime? get externalPostedAt;

  ExternalReviewResponse._();

  factory ExternalReviewResponse([void updates(ExternalReviewResponseBuilder b)]) = _$ExternalReviewResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExternalReviewResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExternalReviewResponse> get serializer => _$ExternalReviewResponseSerializer();
}

class _$ExternalReviewResponseSerializer implements PrimitiveSerializer<ExternalReviewResponse> {
  @override
  final Iterable<Type> types = const [ExternalReviewResponse, _$ExternalReviewResponse];

  @override
  final String wireName = r'ExternalReviewResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExternalReviewResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'author_name';
    yield serializers.serialize(
      object.authorName,
      specifiedType: const FullType(String),
    );
    if (object.authorPhotoUrl != null) {
      yield r'author_photo_url';
      yield serializers.serialize(
        object.authorPhotoUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'rating';
    yield serializers.serialize(
      object.rating,
      specifiedType: const FullType(int),
    );
    if (object.body != null) {
      yield r'body';
      yield serializers.serialize(
        object.body,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(String),
    );
    if (object.sourceUrl != null) {
      yield r'source_url';
      yield serializers.serialize(
        object.sourceUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.externalPostedAt != null) {
      yield r'external_posted_at';
      yield serializers.serialize(
        object.externalPostedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ExternalReviewResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExternalReviewResponseBuilder result,
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
        case r'author_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.authorName = valueDes;
          break;
        case r'author_photo_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.authorPhotoUrl = valueDes;
          break;
        case r'rating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.rating = valueDes;
          break;
        case r'body':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.body = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.source_ = valueDes;
          break;
        case r'source_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.sourceUrl = valueDes;
          break;
        case r'external_posted_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.externalPostedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExternalReviewResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExternalReviewResponseBuilder();
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

