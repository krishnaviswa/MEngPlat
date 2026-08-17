//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'featured_sku.g.dart';

/// FeaturedSku
///
/// Properties:
/// * [code] 
/// * [durationDays] 
/// * [listedPriceInr] 
/// * [amountPaise] 
@BuiltValue()
abstract class FeaturedSku implements Built<FeaturedSku, FeaturedSkuBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'duration_days')
  int get durationDays;

  @BuiltValueField(wireName: r'listed_price_inr')
  int get listedPriceInr;

  @BuiltValueField(wireName: r'amount_paise')
  int? get amountPaise;

  FeaturedSku._();

  factory FeaturedSku([void updates(FeaturedSkuBuilder b)]) = _$FeaturedSku;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FeaturedSkuBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FeaturedSku> get serializer => _$FeaturedSkuSerializer();
}

class _$FeaturedSkuSerializer implements PrimitiveSerializer<FeaturedSku> {
  @override
  final Iterable<Type> types = const [FeaturedSku, _$FeaturedSku];

  @override
  final String wireName = r'FeaturedSku';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FeaturedSku object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'duration_days';
    yield serializers.serialize(
      object.durationDays,
      specifiedType: const FullType(int),
    );
    yield r'listed_price_inr';
    yield serializers.serialize(
      object.listedPriceInr,
      specifiedType: const FullType(int),
    );
    if (object.amountPaise != null) {
      yield r'amount_paise';
      yield serializers.serialize(
        object.amountPaise,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    FeaturedSku object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FeaturedSkuBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'duration_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.durationDays = valueDes;
          break;
        case r'listed_price_inr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.listedPriceInr = valueDes;
          break;
        case r'amount_paise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.amountPaise = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FeaturedSku deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FeaturedSkuBuilder();
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

