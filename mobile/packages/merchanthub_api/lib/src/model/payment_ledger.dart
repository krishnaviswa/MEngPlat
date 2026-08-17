//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'payment_ledger.g.dart';

/// PaymentLedger
///
/// Properties:
/// * [id] 
/// * [status] 
/// * [amountPaise] 
/// * [currency] 
/// * [skuCode] 
/// * [durationDays] 
/// * [platformFeePaise] 
/// * [gatewayFeePaise] 
/// * [provider] 
/// * [providerOrderId] 
/// * [createdAt] 
/// * [approvedAt] 
/// * [rejectedAt] 
@BuiltValue()
abstract class PaymentLedger implements Built<PaymentLedger, PaymentLedgerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'amount_paise')
  int get amountPaise;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'sku_code')
  String? get skuCode;

  @BuiltValueField(wireName: r'duration_days')
  int? get durationDays;

  @BuiltValueField(wireName: r'platform_fee_paise')
  int? get platformFeePaise;

  @BuiltValueField(wireName: r'gateway_fee_paise')
  int? get gatewayFeePaise;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'provider_order_id')
  String get providerOrderId;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'approved_at')
  DateTime? get approvedAt;

  @BuiltValueField(wireName: r'rejected_at')
  DateTime? get rejectedAt;

  PaymentLedger._();

  factory PaymentLedger([void updates(PaymentLedgerBuilder b)]) = _$PaymentLedger;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaymentLedgerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaymentLedger> get serializer => _$PaymentLedgerSerializer();
}

class _$PaymentLedgerSerializer implements PrimitiveSerializer<PaymentLedger> {
  @override
  final Iterable<Type> types = const [PaymentLedger, _$PaymentLedger];

  @override
  final String wireName = r'PaymentLedger';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaymentLedger object, {
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
    yield r'amount_paise';
    yield serializers.serialize(
      object.amountPaise,
      specifiedType: const FullType(int),
    );
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
    if (object.skuCode != null) {
      yield r'sku_code';
      yield serializers.serialize(
        object.skuCode,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.durationDays != null) {
      yield r'duration_days';
      yield serializers.serialize(
        object.durationDays,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.platformFeePaise != null) {
      yield r'platform_fee_paise';
      yield serializers.serialize(
        object.platformFeePaise,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.gatewayFeePaise != null) {
      yield r'gateway_fee_paise';
      yield serializers.serialize(
        object.gatewayFeePaise,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
    );
    yield r'provider_order_id';
    yield serializers.serialize(
      object.providerOrderId,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.approvedAt != null) {
      yield r'approved_at';
      yield serializers.serialize(
        object.approvedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.rejectedAt != null) {
      yield r'rejected_at';
      yield serializers.serialize(
        object.rejectedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PaymentLedger object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaymentLedgerBuilder result,
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
        case r'amount_paise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountPaise = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
          break;
        case r'sku_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.skuCode = valueDes;
          break;
        case r'duration_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.durationDays = valueDes;
          break;
        case r'platform_fee_paise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.platformFeePaise = valueDes;
          break;
        case r'gateway_fee_paise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.gatewayFeePaise = valueDes;
          break;
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.provider = valueDes;
          break;
        case r'provider_order_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.providerOrderId = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'approved_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.approvedAt = valueDes;
          break;
        case r'rejected_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
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
  PaymentLedger deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaymentLedgerBuilder();
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

