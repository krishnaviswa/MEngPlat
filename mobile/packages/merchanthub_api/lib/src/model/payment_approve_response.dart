//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'payment_approve_response.g.dart';

/// PaymentApproveResponse
///
/// Properties:
/// * [id] 
/// * [approvedAt] 
/// * [placementId] 
/// * [endsAt] 
@BuiltValue()
abstract class PaymentApproveResponse implements Built<PaymentApproveResponse, PaymentApproveResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'approved_at')
  DateTime get approvedAt;

  @BuiltValueField(wireName: r'placement_id')
  String get placementId;

  @BuiltValueField(wireName: r'ends_at')
  DateTime get endsAt;

  PaymentApproveResponse._();

  factory PaymentApproveResponse([void updates(PaymentApproveResponseBuilder b)]) = _$PaymentApproveResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaymentApproveResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaymentApproveResponse> get serializer => _$PaymentApproveResponseSerializer();
}

class _$PaymentApproveResponseSerializer implements PrimitiveSerializer<PaymentApproveResponse> {
  @override
  final Iterable<Type> types = const [PaymentApproveResponse, _$PaymentApproveResponse];

  @override
  final String wireName = r'PaymentApproveResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaymentApproveResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'approved_at';
    yield serializers.serialize(
      object.approvedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'placement_id';
    yield serializers.serialize(
      object.placementId,
      specifiedType: const FullType(String),
    );
    yield r'ends_at';
    yield serializers.serialize(
      object.endsAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PaymentApproveResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaymentApproveResponseBuilder result,
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
        case r'approved_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.approvedAt = valueDes;
          break;
        case r'placement_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.placementId = valueDes;
          break;
        case r'ends_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.endsAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PaymentApproveResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaymentApproveResponseBuilder();
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

