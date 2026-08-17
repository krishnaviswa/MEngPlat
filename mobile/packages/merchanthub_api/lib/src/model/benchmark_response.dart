//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'benchmark_response.g.dart';

/// BenchmarkResponse
///
/// Properties:
/// * [businessId] 
/// * [ownRating] 
/// * [categoryMedian] 
/// * [cityMedian] 
/// * [categorySampleSize] 
/// * [citySampleSize] 
/// * [disclaimer] 
@BuiltValue()
abstract class BenchmarkResponse implements Built<BenchmarkResponse, BenchmarkResponseBuilder> {
  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'own_rating')
  num get ownRating;

  @BuiltValueField(wireName: r'category_median')
  num? get categoryMedian;

  @BuiltValueField(wireName: r'city_median')
  num? get cityMedian;

  @BuiltValueField(wireName: r'category_sample_size')
  int get categorySampleSize;

  @BuiltValueField(wireName: r'city_sample_size')
  int get citySampleSize;

  @BuiltValueField(wireName: r'disclaimer')
  String get disclaimer;

  BenchmarkResponse._();

  factory BenchmarkResponse([void updates(BenchmarkResponseBuilder b)]) = _$BenchmarkResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BenchmarkResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BenchmarkResponse> get serializer => _$BenchmarkResponseSerializer();
}

class _$BenchmarkResponseSerializer implements PrimitiveSerializer<BenchmarkResponse> {
  @override
  final Iterable<Type> types = const [BenchmarkResponse, _$BenchmarkResponse];

  @override
  final String wireName = r'BenchmarkResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BenchmarkResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    yield r'own_rating';
    yield serializers.serialize(
      object.ownRating,
      specifiedType: const FullType(num),
    );
    if (object.categoryMedian != null) {
      yield r'category_median';
      yield serializers.serialize(
        object.categoryMedian,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.cityMedian != null) {
      yield r'city_median';
      yield serializers.serialize(
        object.cityMedian,
        specifiedType: const FullType.nullable(num),
      );
    }
    yield r'category_sample_size';
    yield serializers.serialize(
      object.categorySampleSize,
      specifiedType: const FullType(int),
    );
    yield r'city_sample_size';
    yield serializers.serialize(
      object.citySampleSize,
      specifiedType: const FullType(int),
    );
    yield r'disclaimer';
    yield serializers.serialize(
      object.disclaimer,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BenchmarkResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BenchmarkResponseBuilder result,
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
        case r'own_rating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.ownRating = valueDes;
          break;
        case r'category_median':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.categoryMedian = valueDes;
          break;
        case r'city_median':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.cityMedian = valueDes;
          break;
        case r'category_sample_size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.categorySampleSize = valueDes;
          break;
        case r'city_sample_size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.citySampleSize = valueDes;
          break;
        case r'disclaimer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.disclaimer = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BenchmarkResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BenchmarkResponseBuilder();
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

