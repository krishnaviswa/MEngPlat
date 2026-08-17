//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_place_link_request.g.dart';

/// GooglePlaceLinkRequest
///
/// Properties:
/// * [placeId] 
/// * [name] 
/// * [address] 
@BuiltValue()
abstract class GooglePlaceLinkRequest implements Built<GooglePlaceLinkRequest, GooglePlaceLinkRequestBuilder> {
  @BuiltValueField(wireName: r'place_id')
  String get placeId;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'address')
  String? get address;

  GooglePlaceLinkRequest._();

  factory GooglePlaceLinkRequest([void updates(GooglePlaceLinkRequestBuilder b)]) = _$GooglePlaceLinkRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GooglePlaceLinkRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GooglePlaceLinkRequest> get serializer => _$GooglePlaceLinkRequestSerializer();
}

class _$GooglePlaceLinkRequestSerializer implements PrimitiveSerializer<GooglePlaceLinkRequest> {
  @override
  final Iterable<Type> types = const [GooglePlaceLinkRequest, _$GooglePlaceLinkRequest];

  @override
  final String wireName = r'GooglePlaceLinkRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GooglePlaceLinkRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'place_id';
    yield serializers.serialize(
      object.placeId,
      specifiedType: const FullType(String),
    );
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.address != null) {
      yield r'address';
      yield serializers.serialize(
        object.address,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GooglePlaceLinkRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GooglePlaceLinkRequestBuilder result,
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
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.address = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GooglePlaceLinkRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GooglePlaceLinkRequestBuilder();
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

