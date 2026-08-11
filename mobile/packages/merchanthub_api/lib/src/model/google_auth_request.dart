//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_auth_request.g.dart';

/// GoogleAuthRequest
///
/// Properties:
/// * [credential] 
@BuiltValue()
abstract class GoogleAuthRequest implements Built<GoogleAuthRequest, GoogleAuthRequestBuilder> {
  @BuiltValueField(wireName: r'credential')
  String get credential;

  GoogleAuthRequest._();

  factory GoogleAuthRequest([void updates(GoogleAuthRequestBuilder b)]) = _$GoogleAuthRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GoogleAuthRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GoogleAuthRequest> get serializer => _$GoogleAuthRequestSerializer();
}

class _$GoogleAuthRequestSerializer implements PrimitiveSerializer<GoogleAuthRequest> {
  @override
  final Iterable<Type> types = const [GoogleAuthRequest, _$GoogleAuthRequest];

  @override
  final String wireName = r'GoogleAuthRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GoogleAuthRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'credential';
    yield serializers.serialize(
      object.credential,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GoogleAuthRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GoogleAuthRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'credential':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.credential = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GoogleAuthRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GoogleAuthRequestBuilder();
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

