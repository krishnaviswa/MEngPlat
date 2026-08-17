//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mock_complete_request.g.dart';

/// MockCompleteRequest
///
/// Properties:
/// * [providerOrderId] 
/// * [outcome] 
@BuiltValue()
abstract class MockCompleteRequest implements Built<MockCompleteRequest, MockCompleteRequestBuilder> {
  @BuiltValueField(wireName: r'provider_order_id')
  String get providerOrderId;

  @BuiltValueField(wireName: r'outcome')
  String get outcome;

  MockCompleteRequest._();

  factory MockCompleteRequest([void updates(MockCompleteRequestBuilder b)]) = _$MockCompleteRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MockCompleteRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MockCompleteRequest> get serializer => _$MockCompleteRequestSerializer();
}

class _$MockCompleteRequestSerializer implements PrimitiveSerializer<MockCompleteRequest> {
  @override
  final Iterable<Type> types = const [MockCompleteRequest, _$MockCompleteRequest];

  @override
  final String wireName = r'MockCompleteRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MockCompleteRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'provider_order_id';
    yield serializers.serialize(
      object.providerOrderId,
      specifiedType: const FullType(String),
    );
    yield r'outcome';
    yield serializers.serialize(
      object.outcome,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MockCompleteRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MockCompleteRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'provider_order_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.providerOrderId = valueDes;
          break;
        case r'outcome':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.outcome = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MockCompleteRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MockCompleteRequestBuilder();
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

