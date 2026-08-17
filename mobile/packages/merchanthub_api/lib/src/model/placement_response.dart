//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/featured_sku.dart';
import 'package:merchanthub_api/src/model/payment_ledger.dart';
import 'package:built_collection/built_collection.dart';
import 'package:merchanthub_api/src/model/placement_window.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'placement_response.g.dart';

/// PlacementResponse
///
/// Properties:
/// * [businessId] 
/// * [active] 
/// * [placement] 
/// * [sku] 
/// * [skus] 
/// * [awaitingApproval] 
/// * [payment] 
@BuiltValue()
abstract class PlacementResponse implements Built<PlacementResponse, PlacementResponseBuilder> {
  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'active')
  bool get active;

  @BuiltValueField(wireName: r'placement')
  PlacementWindow? get placement;

  @BuiltValueField(wireName: r'sku')
  FeaturedSku get sku;

  @BuiltValueField(wireName: r'skus')
  BuiltList<FeaturedSku>? get skus;

  @BuiltValueField(wireName: r'awaiting_approval')
  bool? get awaitingApproval;

  @BuiltValueField(wireName: r'payment')
  PaymentLedger? get payment;

  PlacementResponse._();

  factory PlacementResponse([void updates(PlacementResponseBuilder b)]) = _$PlacementResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlacementResponseBuilder b) => b
      ..skus = ListBuilder()
      ..awaitingApproval = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlacementResponse> get serializer => _$PlacementResponseSerializer();
}

class _$PlacementResponseSerializer implements PrimitiveSerializer<PlacementResponse> {
  @override
  final Iterable<Type> types = const [PlacementResponse, _$PlacementResponse];

  @override
  final String wireName = r'PlacementResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlacementResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    yield r'active';
    yield serializers.serialize(
      object.active,
      specifiedType: const FullType(bool),
    );
    if (object.placement != null) {
      yield r'placement';
      yield serializers.serialize(
        object.placement,
        specifiedType: const FullType(PlacementWindow),
      );
    }
    yield r'sku';
    yield serializers.serialize(
      object.sku,
      specifiedType: const FullType(FeaturedSku),
    );
    if (object.skus != null) {
      yield r'skus';
      yield serializers.serialize(
        object.skus,
        specifiedType: const FullType(BuiltList, [FullType(FeaturedSku)]),
      );
    }
    if (object.awaitingApproval != null) {
      yield r'awaiting_approval';
      yield serializers.serialize(
        object.awaitingApproval,
        specifiedType: const FullType(bool),
      );
    }
    if (object.payment != null) {
      yield r'payment';
      yield serializers.serialize(
        object.payment,
        specifiedType: const FullType(PaymentLedger),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlacementResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlacementResponseBuilder result,
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
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        case r'placement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlacementWindow),
          ) as PlacementWindow;
          result.placement.replace(valueDes);
          break;
        case r'sku':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FeaturedSku),
          ) as FeaturedSku;
          result.sku.replace(valueDes);
          break;
        case r'skus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FeaturedSku)]),
          ) as BuiltList<FeaturedSku>;
          result.skus.replace(valueDes);
          break;
        case r'awaiting_approval':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.awaitingApproval = valueDes;
          break;
        case r'payment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PaymentLedger),
          ) as PaymentLedger;
          result.payment.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlacementResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlacementResponseBuilder();
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

