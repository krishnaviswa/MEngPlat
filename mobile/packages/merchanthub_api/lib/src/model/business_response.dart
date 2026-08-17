//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/business_status.dart';
import 'package:merchanthub_api/src/model/category_response.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'business_response.g.dart';

/// BusinessResponse
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [slug] 
/// * [description] 
/// * [address] 
/// * [city] 
/// * [state] 
/// * [postalCode] 
/// * [country] 
/// * [latitude] 
/// * [longitude] 
/// * [phone] 
/// * [email] 
/// * [website] 
/// * [logoUrl] 
/// * [storefrontUrl] 
/// * [businessHours] 
/// * [status] 
/// * [averageRating] 
/// * [reviewCount] 
/// * [aiMerchantSummary] 
/// * [categories] 
/// * [isFeatured] 
@BuiltValue()
abstract class BusinessResponse implements Built<BusinessResponse, BusinessResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'address')
  String get address;

  @BuiltValueField(wireName: r'city')
  String get city;

  @BuiltValueField(wireName: r'state')
  String? get state;

  @BuiltValueField(wireName: r'postal_code')
  String? get postalCode;

  @BuiltValueField(wireName: r'country')
  String get country;

  @BuiltValueField(wireName: r'latitude')
  num? get latitude;

  @BuiltValueField(wireName: r'longitude')
  num? get longitude;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'website')
  String? get website;

  @BuiltValueField(wireName: r'logo_url')
  String? get logoUrl;

  @BuiltValueField(wireName: r'storefront_url')
  String? get storefrontUrl;

  @BuiltValueField(wireName: r'business_hours')
  JsonObject? get businessHours;

  @BuiltValueField(wireName: r'status')
  BusinessStatus get status;
  // enum statusEnum {  pending,  approved,  rejected,  suspended,  };

  @BuiltValueField(wireName: r'average_rating')
  num get averageRating;

  @BuiltValueField(wireName: r'review_count')
  int get reviewCount;

  @BuiltValueField(wireName: r'ai_merchant_summary')
  String? get aiMerchantSummary;

  @BuiltValueField(wireName: r'categories')
  BuiltList<CategoryResponse>? get categories;

  @BuiltValueField(wireName: r'is_featured')
  bool? get isFeatured;

  BusinessResponse._();

  factory BusinessResponse([void updates(BusinessResponseBuilder b)]) = _$BusinessResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BusinessResponseBuilder b) => b
      ..categories = ListBuilder()
      ..isFeatured = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<BusinessResponse> get serializer => _$BusinessResponseSerializer();
}

class _$BusinessResponseSerializer implements PrimitiveSerializer<BusinessResponse> {
  @override
  final Iterable<Type> types = const [BusinessResponse, _$BusinessResponse];

  @override
  final String wireName = r'BusinessResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BusinessResponse object, {
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
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'address';
    yield serializers.serialize(
      object.address,
      specifiedType: const FullType(String),
    );
    yield r'city';
    yield serializers.serialize(
      object.city,
      specifiedType: const FullType(String),
    );
    if (object.state != null) {
      yield r'state';
      yield serializers.serialize(
        object.state,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.postalCode != null) {
      yield r'postal_code';
      yield serializers.serialize(
        object.postalCode,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'country';
    yield serializers.serialize(
      object.country,
      specifiedType: const FullType(String),
    );
    if (object.latitude != null) {
      yield r'latitude';
      yield serializers.serialize(
        object.latitude,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.longitude != null) {
      yield r'longitude';
      yield serializers.serialize(
        object.longitude,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.website != null) {
      yield r'website';
      yield serializers.serialize(
        object.website,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.logoUrl != null) {
      yield r'logo_url';
      yield serializers.serialize(
        object.logoUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.storefrontUrl != null) {
      yield r'storefront_url';
      yield serializers.serialize(
        object.storefrontUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.businessHours != null) {
      yield r'business_hours';
      yield serializers.serialize(
        object.businessHours,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(BusinessStatus),
    );
    yield r'average_rating';
    yield serializers.serialize(
      object.averageRating,
      specifiedType: const FullType(num),
    );
    yield r'review_count';
    yield serializers.serialize(
      object.reviewCount,
      specifiedType: const FullType(int),
    );
    if (object.aiMerchantSummary != null) {
      yield r'ai_merchant_summary';
      yield serializers.serialize(
        object.aiMerchantSummary,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.categories != null) {
      yield r'categories';
      yield serializers.serialize(
        object.categories,
        specifiedType: const FullType(BuiltList, [FullType(CategoryResponse)]),
      );
    }
    if (object.isFeatured != null) {
      yield r'is_featured';
      yield serializers.serialize(
        object.isFeatured,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BusinessResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BusinessResponseBuilder result,
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
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.address = valueDes;
          break;
        case r'city':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.city = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.state = valueDes;
          break;
        case r'postal_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.postalCode = valueDes;
          break;
        case r'country':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.country = valueDes;
          break;
        case r'latitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.latitude = valueDes;
          break;
        case r'longitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.longitude = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.phone = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        case r'website':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.website = valueDes;
          break;
        case r'logo_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.logoUrl = valueDes;
          break;
        case r'storefront_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.storefrontUrl = valueDes;
          break;
        case r'business_hours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.businessHours = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BusinessStatus),
          ) as BusinessStatus;
          result.status = valueDes;
          break;
        case r'average_rating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.averageRating = valueDes;
          break;
        case r'review_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.reviewCount = valueDes;
          break;
        case r'ai_merchant_summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.aiMerchantSummary = valueDes;
          break;
        case r'categories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CategoryResponse)]),
          ) as BuiltList<CategoryResponse>;
          result.categories.replace(valueDes);
          break;
        case r'is_featured':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isFeatured = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BusinessResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BusinessResponseBuilder();
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

