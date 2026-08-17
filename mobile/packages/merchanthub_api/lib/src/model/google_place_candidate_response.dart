//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_place_candidate_response.g.dart';

/// GooglePlaceCandidateResponse
///
/// Properties:
/// * [placeId] 
/// * [name] 
/// * [address] 
/// * [latitude] 
/// * [longitude] 
@BuiltValue()
abstract class GooglePlaceCandidateResponse implements Built<GooglePlaceCandidateResponse, GooglePlaceCandidateResponseBuilder> {
  @BuiltValueField(wireName: r'place_id')
  String get placeId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'address')
  String get address;

  @BuiltValueField(wireName: r'latitude')
  num get latitude;

  @BuiltValueField(wireName: r'longitude')
  num get longitude;

  GooglePlaceCandidateResponse._();

  factory GooglePlaceCandidateResponse([void updates(GooglePlaceCandidateResponseBuilder b)]) = _$GooglePlaceCandidateResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GooglePlaceCandidateResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GooglePlaceCandidateResponse> get serializer => _$GooglePlaceCandidateResponseSerializer();
}

class _$GooglePlaceCandidateResponseSerializer implements PrimitiveSerializer<GooglePlaceCandidateResponse> {
  @override
  final Iterable<Type> types = const [GooglePlaceCandidateResponse, _$GooglePlaceCandidateResponse];

  @override
  final String wireName = r'GooglePlaceCandidateResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GooglePlaceCandidateResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'place_id';
    yield serializers.serialize(
      object.placeId,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'address';
    yield serializers.serialize(
      object.address,
      specifiedType: const FullType(String),
    );
    yield r'latitude';
    yield serializers.serialize(
      object.latitude,
      specifiedType: const FullType(num),
    );
    yield r'longitude';
    yield serializers.serialize(
      object.longitude,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GooglePlaceCandidateResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GooglePlaceCandidateResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'place_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.placeId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.address = valueDes;
          break;
        case r'latitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.latitude = valueDes;
          break;
        case r'longitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.longitude = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GooglePlaceCandidateResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GooglePlaceCandidateResponseBuilder();
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

