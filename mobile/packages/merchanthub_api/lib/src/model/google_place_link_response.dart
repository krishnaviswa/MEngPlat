//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_place_link_response.g.dart';

/// GooglePlaceLinkResponse
///
/// Properties:
/// * [linked] 
/// * [placeId] 
@BuiltValue()
abstract class GooglePlaceLinkResponse implements Built<GooglePlaceLinkResponse, GooglePlaceLinkResponseBuilder> {
  @BuiltValueField(wireName: r'linked')
  bool get linked;

  @BuiltValueField(wireName: r'place_id')
  String get placeId;

  GooglePlaceLinkResponse._();

  factory GooglePlaceLinkResponse([void updates(GooglePlaceLinkResponseBuilder b)]) = _$GooglePlaceLinkResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GooglePlaceLinkResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GooglePlaceLinkResponse> get serializer => _$GooglePlaceLinkResponseSerializer();
}

class _$GooglePlaceLinkResponseSerializer implements PrimitiveSerializer<GooglePlaceLinkResponse> {
  @override
  final Iterable<Type> types = const [GooglePlaceLinkResponse, _$GooglePlaceLinkResponse];

  @override
  final String wireName = r'GooglePlaceLinkResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GooglePlaceLinkResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'linked';
    yield serializers.serialize(
      object.linked,
      specifiedType: const FullType(bool),
    );
    yield r'place_id';
    yield serializers.serialize(
      object.placeId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GooglePlaceLinkResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GooglePlaceLinkResponseBuilder result,
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
            specifiedType: const FullType(String),
          ) as String;
          result.placeId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GooglePlaceLinkResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GooglePlaceLinkResponseBuilder();
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

