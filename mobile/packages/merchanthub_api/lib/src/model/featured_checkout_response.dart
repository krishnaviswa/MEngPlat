//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/featured_sku.dart';
import 'package:merchanthub_api/src/model/checkout_fields.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'featured_checkout_response.g.dart';

/// FeaturedCheckoutResponse
///
/// Properties:
/// * [paymentId] 
/// * [provider] 
/// * [providerOrderId] 
/// * [amountPaise] 
/// * [currency] 
/// * [sku] 
/// * [checkout] 
@BuiltValue()
abstract class FeaturedCheckoutResponse implements Built<FeaturedCheckoutResponse, FeaturedCheckoutResponseBuilder> {
  @BuiltValueField(wireName: r'payment_id')
  String get paymentId;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'provider_order_id')
  String get providerOrderId;

  @BuiltValueField(wireName: r'amount_paise')
  int get amountPaise;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'sku')
  FeaturedSku get sku;

  @BuiltValueField(wireName: r'checkout')
  CheckoutFields get checkout;

  FeaturedCheckoutResponse._();

  factory FeaturedCheckoutResponse([void updates(FeaturedCheckoutResponseBuilder b)]) = _$FeaturedCheckoutResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FeaturedCheckoutResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FeaturedCheckoutResponse> get serializer => _$FeaturedCheckoutResponseSerializer();
}

class _$FeaturedCheckoutResponseSerializer implements PrimitiveSerializer<FeaturedCheckoutResponse> {
  @override
  final Iterable<Type> types = const [FeaturedCheckoutResponse, _$FeaturedCheckoutResponse];

  @override
  final String wireName = r'FeaturedCheckoutResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FeaturedCheckoutResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'payment_id';
    yield serializers.serialize(
      object.paymentId,
      specifiedType: const FullType(String),
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
    yield r'sku';
    yield serializers.serialize(
      object.sku,
      specifiedType: const FullType(FeaturedSku),
    );
    yield r'checkout';
    yield serializers.serialize(
      object.checkout,
      specifiedType: const FullType(CheckoutFields),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FeaturedCheckoutResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FeaturedCheckoutResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'payment_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.paymentId = valueDes;
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
        case r'sku':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FeaturedSku),
          ) as FeaturedSku;
          result.sku.replace(valueDes);
          break;
        case r'checkout':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CheckoutFields),
          ) as CheckoutFields;
          result.checkout.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FeaturedCheckoutResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FeaturedCheckoutResponseBuilder();
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

