//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'featured_checkout_request.g.dart';

/// FeaturedCheckoutRequest
///
/// Properties:
/// * [businessId] 
/// * [skuCode] 
@BuiltValue()
abstract class FeaturedCheckoutRequest implements Built<FeaturedCheckoutRequest, FeaturedCheckoutRequestBuilder> {
  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'sku_code')
  String get skuCode;

  FeaturedCheckoutRequest._();

  factory FeaturedCheckoutRequest([void updates(FeaturedCheckoutRequestBuilder b)]) = _$FeaturedCheckoutRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FeaturedCheckoutRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FeaturedCheckoutRequest> get serializer => _$FeaturedCheckoutRequestSerializer();
}

class _$FeaturedCheckoutRequestSerializer implements PrimitiveSerializer<FeaturedCheckoutRequest> {
  @override
  final Iterable<Type> types = const [FeaturedCheckoutRequest, _$FeaturedCheckoutRequest];

  @override
  final String wireName = r'FeaturedCheckoutRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FeaturedCheckoutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    yield r'sku_code';
    yield serializers.serialize(
      object.skuCode,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FeaturedCheckoutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FeaturedCheckoutRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'business_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.businessId = valueDes;
          break;
        case r'sku_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.skuCode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FeaturedCheckoutRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FeaturedCheckoutRequestBuilder();
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

