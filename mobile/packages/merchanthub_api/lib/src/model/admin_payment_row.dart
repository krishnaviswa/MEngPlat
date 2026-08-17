//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_payment_row.g.dart';

/// AdminPaymentRow
///
/// Properties:
/// * [id] 
/// * [status] 
/// * [amountPaise] 
/// * [currency] 
/// * [skuCode] 
/// * [durationDays] 
/// * [provider] 
/// * [providerOrderId] 
/// * [createdAt] 
/// * [approvedAt] 
/// * [rejectedAt] 
/// * [platformFeePaise] 
/// * [gatewayFeePaise] 
/// * [businessId] 
/// * [businessName] 
/// * [merchantUserId] 
/// * [merchantEmail] 
/// * [merchantName] 
/// * [merchantPaymentCount] 
/// * [awaitingApproval] 
@BuiltValue()
abstract class AdminPaymentRow implements Built<AdminPaymentRow, AdminPaymentRowBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'amount_paise')
  int get amountPaise;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'sku_code')
  String get skuCode;

  @BuiltValueField(wireName: r'duration_days')
  int get durationDays;

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

  @BuiltValueField(wireName: r'platform_fee_paise')
  int? get platformFeePaise;

  @BuiltValueField(wireName: r'gateway_fee_paise')
  int? get gatewayFeePaise;

  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'business_name')
  String get businessName;

  @BuiltValueField(wireName: r'merchant_user_id')
  String get merchantUserId;

  @BuiltValueField(wireName: r'merchant_email')
  String get merchantEmail;

  @BuiltValueField(wireName: r'merchant_name')
  String get merchantName;

  @BuiltValueField(wireName: r'merchant_payment_count')
  int get merchantPaymentCount;

  @BuiltValueField(wireName: r'awaiting_approval')
  bool get awaitingApproval;

  AdminPaymentRow._();

  factory AdminPaymentRow([void updates(AdminPaymentRowBuilder b)]) = _$AdminPaymentRow;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminPaymentRowBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminPaymentRow> get serializer => _$AdminPaymentRowSerializer();
}

class _$AdminPaymentRowSerializer implements PrimitiveSerializer<AdminPaymentRow> {
  @override
  final Iterable<Type> types = const [AdminPaymentRow, _$AdminPaymentRow];

  @override
  final String wireName = r'AdminPaymentRow';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminPaymentRow object, {
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
    yield r'sku_code';
    yield serializers.serialize(
      object.skuCode,
      specifiedType: const FullType(String),
    );
    yield r'duration_days';
    yield serializers.serialize(
      object.durationDays,
      specifiedType: const FullType(int),
    );
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
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    yield r'business_name';
    yield serializers.serialize(
      object.businessName,
      specifiedType: const FullType(String),
    );
    yield r'merchant_user_id';
    yield serializers.serialize(
      object.merchantUserId,
      specifiedType: const FullType(String),
    );
    yield r'merchant_email';
    yield serializers.serialize(
      object.merchantEmail,
      specifiedType: const FullType(String),
    );
    yield r'merchant_name';
    yield serializers.serialize(
      object.merchantName,
      specifiedType: const FullType(String),
    );
    yield r'merchant_payment_count';
    yield serializers.serialize(
      object.merchantPaymentCount,
      specifiedType: const FullType(int),
    );
    yield r'awaiting_approval';
    yield serializers.serialize(
      object.awaitingApproval,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminPaymentRow object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminPaymentRowBuilder result,
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
            specifiedType: const FullType(String),
          ) as String;
          result.skuCode = valueDes;
          break;
        case r'duration_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.durationDays = valueDes;
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
        case r'business_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.businessId = valueDes;
          break;
        case r'business_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.businessName = valueDes;
          break;
        case r'merchant_user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.merchantUserId = valueDes;
          break;
        case r'merchant_email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.merchantEmail = valueDes;
          break;
        case r'merchant_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.merchantName = valueDes;
          break;
        case r'merchant_payment_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.merchantPaymentCount = valueDes;
          break;
        case r'awaiting_approval':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.awaitingApproval = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminPaymentRow deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminPaymentRowBuilder();
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

