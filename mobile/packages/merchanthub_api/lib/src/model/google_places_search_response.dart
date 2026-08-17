//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:merchanthub_api/src/model/google_place_candidate_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_places_search_response.g.dart';

/// GooglePlacesSearchResponse
///
/// Properties:
/// * [candidates] 
@BuiltValue()
abstract class GooglePlacesSearchResponse implements Built<GooglePlacesSearchResponse, GooglePlacesSearchResponseBuilder> {
  @BuiltValueField(wireName: r'candidates')
  BuiltList<GooglePlaceCandidateResponse> get candidates;

  GooglePlacesSearchResponse._();

  factory GooglePlacesSearchResponse([void updates(GooglePlacesSearchResponseBuilder b)]) = _$GooglePlacesSearchResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GooglePlacesSearchResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GooglePlacesSearchResponse> get serializer => _$GooglePlacesSearchResponseSerializer();
}

class _$GooglePlacesSearchResponseSerializer implements PrimitiveSerializer<GooglePlacesSearchResponse> {
  @override
  final Iterable<Type> types = const [GooglePlacesSearchResponse, _$GooglePlacesSearchResponse];

  @override
  final String wireName = r'GooglePlacesSearchResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GooglePlacesSearchResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'candidates';
    yield serializers.serialize(
      object.candidates,
      specifiedType: const FullType(BuiltList, [FullType(GooglePlaceCandidateResponse)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GooglePlacesSearchResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GooglePlacesSearchResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'candidates':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GooglePlaceCandidateResponse)]),
          ) as BuiltList<GooglePlaceCandidateResponse>;
          result.candidates.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GooglePlacesSearchResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GooglePlacesSearchResponseBuilder();
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

