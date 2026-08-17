//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'payment_refund_response.g.dart';

/// PaymentRefundResponse
///
/// Properties:
/// * [id] 
/// * [status] 
@BuiltValue()
abstract class PaymentRefundResponse implements Built<PaymentRefundResponse, PaymentRefundResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  String get status;

  PaymentRefundResponse._();

  factory PaymentRefundResponse([void updates(PaymentRefundResponseBuilder b)]) = _$PaymentRefundResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaymentRefundResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaymentRefundResponse> get serializer => _$PaymentRefundResponseSerializer();
}

class _$PaymentRefundResponseSerializer implements PrimitiveSerializer<PaymentRefundResponse> {
  @override
  final Iterable<Type> types = const [PaymentRefundResponse, _$PaymentRefundResponse];

  @override
  final String wireName = r'PaymentRefundResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaymentRefundResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PaymentRefundResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaymentRefundResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PaymentRefundResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaymentRefundResponseBuilder();
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

