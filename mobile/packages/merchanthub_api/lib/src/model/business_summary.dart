//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/business_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'business_summary.g.dart';

/// BusinessSummary
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [slug] 
/// * [city] 
/// * [status] 
@BuiltValue()
abstract class BusinessSummary implements Built<BusinessSummary, BusinessSummaryBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'city')
  String? get city;

  @BuiltValueField(wireName: r'status')
  BusinessStatus get status;
  // enum statusEnum {  pending,  approved,  rejected,  suspended,  };

  BusinessSummary._();

  factory BusinessSummary([void updates(BusinessSummaryBuilder b)]) = _$BusinessSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BusinessSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BusinessSummary> get serializer => _$BusinessSummarySerializer();
}

class _$BusinessSummarySerializer implements PrimitiveSerializer<BusinessSummary> {
  @override
  final Iterable<Type> types = const [BusinessSummary, _$BusinessSummary];

  @override
  final String wireName = r'BusinessSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BusinessSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    if (object.city != null) {
      yield r'city';
      yield serializers.serialize(
        object.city,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(BusinessStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BusinessSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BusinessSummaryBuilder result,
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
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'city':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.city = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BusinessStatus),
          ) as BusinessStatus;
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
  BusinessSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BusinessSummaryBuilder();
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

