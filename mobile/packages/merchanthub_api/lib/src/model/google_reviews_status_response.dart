//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_reviews_status_response.g.dart';

/// GoogleReviewsStatusResponse
///
/// Properties:
/// * [linked] 
/// * [placeId] 
/// * [reviewCount] 
/// * [lastSyncedAt] 
@BuiltValue()
abstract class GoogleReviewsStatusResponse implements Built<GoogleReviewsStatusResponse, GoogleReviewsStatusResponseBuilder> {
  @BuiltValueField(wireName: r'linked')
  bool get linked;

  @BuiltValueField(wireName: r'place_id')
  String? get placeId;

  @BuiltValueField(wireName: r'review_count')
  int get reviewCount;

  @BuiltValueField(wireName: r'last_synced_at')
  DateTime? get lastSyncedAt;

  GoogleReviewsStatusResponse._();

  factory GoogleReviewsStatusResponse([void updates(GoogleReviewsStatusResponseBuilder b)]) = _$GoogleReviewsStatusResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GoogleReviewsStatusResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GoogleReviewsStatusResponse> get serializer => _$GoogleReviewsStatusResponseSerializer();
}

class _$GoogleReviewsStatusResponseSerializer implements PrimitiveSerializer<GoogleReviewsStatusResponse> {
  @override
  final Iterable<Type> types = const [GoogleReviewsStatusResponse, _$GoogleReviewsStatusResponse];

  @override
  final String wireName = r'GoogleReviewsStatusResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GoogleReviewsStatusResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'linked';
    yield serializers.serialize(
      object.linked,
      specifiedType: const FullType(bool),
    );
    if (object.placeId != null) {
      yield r'place_id';
      yield serializers.serialize(
        object.placeId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'review_count';
    yield serializers.serialize(
      object.reviewCount,
      specifiedType: const FullType(int),
    );
    if (object.lastSyncedAt != null) {
      yield r'last_synced_at';
      yield serializers.serialize(
        object.lastSyncedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GoogleReviewsStatusResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GoogleReviewsStatusResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'linked':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.linked = valueDes;
          break;
        case r'place_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.placeId = valueDes;
          break;
        case r'review_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.reviewCount = valueDes;
          break;
        case r'last_synced_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastSyncedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GoogleReviewsStatusResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GoogleReviewsStatusResponseBuilder();
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

