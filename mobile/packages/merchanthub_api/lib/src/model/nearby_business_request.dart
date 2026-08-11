//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'nearby_business_request.g.dart';

/// NearbyBusinessRequest
///
/// Properties:
/// * [lat] 
/// * [lng] 
/// * [radiusKm] 
@BuiltValue()
abstract class NearbyBusinessRequest implements Built<NearbyBusinessRequest, NearbyBusinessRequestBuilder> {
  @BuiltValueField(wireName: r'lat')
  num get lat;

  @BuiltValueField(wireName: r'lng')
  num get lng;

  @BuiltValueField(wireName: r'radius_km')
  num? get radiusKm;

  NearbyBusinessRequest._();

  factory NearbyBusinessRequest([void updates(NearbyBusinessRequestBuilder b)]) = _$NearbyBusinessRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NearbyBusinessRequestBuilder b) => b
      ..radiusKm = 10.0;

  @BuiltValueSerializer(custom: true)
  static Serializer<NearbyBusinessRequest> get serializer => _$NearbyBusinessRequestSerializer();
}

class _$NearbyBusinessRequestSerializer implements PrimitiveSerializer<NearbyBusinessRequest> {
  @override
  final Iterable<Type> types = const [NearbyBusinessRequest, _$NearbyBusinessRequest];

  @override
  final String wireName = r'NearbyBusinessRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NearbyBusinessRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'lat';
    yield serializers.serialize(
      object.lat,
      specifiedType: const FullType(num),
    );
    yield r'lng';
    yield serializers.serialize(
      object.lng,
      specifiedType: const FullType(num),
    );
    if (object.radiusKm != null) {
      yield r'radius_km';
      yield serializers.serialize(
        object.radiusKm,
        specifiedType: const FullType(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    NearbyBusinessRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NearbyBusinessRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.lat = valueDes;
          break;
        case r'lng':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.lng = valueDes;
          break;
        case r'radius_km':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.radiusKm = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NearbyBusinessRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NearbyBusinessRequestBuilder();
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

