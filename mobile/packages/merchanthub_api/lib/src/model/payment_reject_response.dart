//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'payment_reject_response.g.dart';

/// PaymentRejectResponse
///
/// Properties:
/// * [id] 
/// * [rejectedAt] 
@BuiltValue()
abstract class PaymentRejectResponse implements Built<PaymentRejectResponse, PaymentRejectResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'rejected_at')
  DateTime get rejectedAt;

  PaymentRejectResponse._();

  factory PaymentRejectResponse([void updates(PaymentRejectResponseBuilder b)]) = _$PaymentRejectResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaymentRejectResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaymentRejectResponse> get serializer => _$PaymentRejectResponseSerializer();
}

class _$PaymentRejectResponseSerializer implements PrimitiveSerializer<PaymentRejectResponse> {
  @override
  final Iterable<Type> types = const [PaymentRejectResponse, _$PaymentRejectResponse];

  @override
  final String wireName = r'PaymentRejectResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaymentRejectResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'rejected_at';
    yield serializers.serialize(
      object.rejectedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PaymentRejectResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaymentRejectResponseBuilder result,
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
        case r'rejected_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.rejectedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PaymentRejectResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaymentRejectResponseBuilder();
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

