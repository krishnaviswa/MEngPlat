//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_reviews_sync_response.g.dart';

/// GoogleReviewsSyncResponse
///
/// Properties:
/// * [syncedCount] 
/// * [lastSyncedAt] 
/// * [debounced] 
@BuiltValue()
abstract class GoogleReviewsSyncResponse implements Built<GoogleReviewsSyncResponse, GoogleReviewsSyncResponseBuilder> {
  @BuiltValueField(wireName: r'synced_count')
  int get syncedCount;

  @BuiltValueField(wireName: r'last_synced_at')
  DateTime get lastSyncedAt;

  @BuiltValueField(wireName: r'debounced')
  bool get debounced;

  GoogleReviewsSyncResponse._();

  factory GoogleReviewsSyncResponse([void updates(GoogleReviewsSyncResponseBuilder b)]) = _$GoogleReviewsSyncResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GoogleReviewsSyncResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GoogleReviewsSyncResponse> get serializer => _$GoogleReviewsSyncResponseSerializer();
}

class _$GoogleReviewsSyncResponseSerializer implements PrimitiveSerializer<GoogleReviewsSyncResponse> {
  @override
  final Iterable<Type> types = const [GoogleReviewsSyncResponse, _$GoogleReviewsSyncResponse];

  @override
  final String wireName = r'GoogleReviewsSyncResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GoogleReviewsSyncResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'synced_count';
    yield serializers.serialize(
      object.syncedCount,
      specifiedType: const FullType(int),
    );
    yield r'last_synced_at';
    yield serializers.serialize(
      object.lastSyncedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'debounced';
    yield serializers.serialize(
      object.debounced,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GoogleReviewsSyncResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GoogleReviewsSyncResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'synced_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.syncedCount = valueDes;
          break;
        case r'last_synced_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.lastSyncedAt = valueDes;
          break;
        case r'debounced':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.debounced = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GoogleReviewsSyncResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GoogleReviewsSyncResponseBuilder();
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

