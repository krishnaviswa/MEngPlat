//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_places_search_request.g.dart';

/// GooglePlacesSearchRequest
///
/// Properties:
/// * [query] 
@BuiltValue()
abstract class GooglePlacesSearchRequest implements Built<GooglePlacesSearchRequest, GooglePlacesSearchRequestBuilder> {
  @BuiltValueField(wireName: r'query')
  String get query;

  GooglePlacesSearchRequest._();

  factory GooglePlacesSearchRequest([void updates(GooglePlacesSearchRequestBuilder b)]) = _$GooglePlacesSearchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GooglePlacesSearchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GooglePlacesSearchRequest> get serializer => _$GooglePlacesSearchRequestSerializer();
}

class _$GooglePlacesSearchRequestSerializer implements PrimitiveSerializer<GooglePlacesSearchRequest> {
  @override
  final Iterable<Type> types = const [GooglePlacesSearchRequest, _$GooglePlacesSearchRequest];

  @override
  final String wireName = r'GooglePlacesSearchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GooglePlacesSearchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'query';
    yield serializers.serialize(
      object.query,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GooglePlacesSearchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GooglePlacesSearchRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'query':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.query = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GooglePlacesSearchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GooglePlacesSearchRequestBuilder();
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

