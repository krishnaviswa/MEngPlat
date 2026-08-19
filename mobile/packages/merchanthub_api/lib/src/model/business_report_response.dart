//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/business_report_message_response.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'business_report_response.g.dart';

/// BusinessReportResponse
///
/// Properties:
/// * [id] 
/// * [businessId] 
/// * [reporterId] 
/// * [reason] 
/// * [status] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [businessName] 
/// * [messages] 
/// * [reportCount] 
/// * [isRepeat] 
@BuiltValue()
abstract class BusinessReportResponse implements Built<BusinessReportResponse, BusinessReportResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'business_id')
  String get businessId;

  @BuiltValueField(wireName: r'reporter_id')
  String get reporterId;

  @BuiltValueField(wireName: r'reason')
  String get reason;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'business_name')
  String? get businessName;

  @BuiltValueField(wireName: r'messages')
  BuiltList<BusinessReportMessageResponse>? get messages;

  @BuiltValueField(wireName: r'report_count')
  int? get reportCount;

  @BuiltValueField(wireName: r'is_repeat')
  bool? get isRepeat;

  BusinessReportResponse._();

  factory BusinessReportResponse([void updates(BusinessReportResponseBuilder b)]) = _$BusinessReportResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BusinessReportResponseBuilder b) => b
      ..isRepeat = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<BusinessReportResponse> get serializer => _$BusinessReportResponseSerializer();
}

class _$BusinessReportResponseSerializer implements PrimitiveSerializer<BusinessReportResponse> {
  @override
  final Iterable<Type> types = const [BusinessReportResponse, _$BusinessReportResponse];

  @override
  final String wireName = r'BusinessReportResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BusinessReportResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'business_id';
    yield serializers.serialize(
      object.businessId,
      specifiedType: const FullType(String),
    );
    yield r'reporter_id';
    yield serializers.serialize(
      object.reporterId,
      specifiedType: const FullType(String),
    );
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.businessName != null) {
      yield r'business_name';
      yield serializers.serialize(
        object.businessName,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.messages != null) {
      yield r'messages';
      yield serializers.serialize(
        object.messages,
        specifiedType: const FullType(BuiltList, [FullType(BusinessReportMessageResponse)]),
      );
    }
    if (object.reportCount != null) {
      yield r'report_count';
      yield serializers.serialize(
        object.reportCount,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.isRepeat != null) {
      yield r'is_repeat';
      yield serializers.serialize(
        object.isRepeat,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BusinessReportResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BusinessReportResponseBuilder result,
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
        case r'business_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.businessId = valueDes;
          break;
        case r'reporter_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reporterId = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'business_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.businessName = valueDes;
          break;
        case r'messages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(BusinessReportMessageResponse)]),
          ) as BuiltList<BusinessReportMessageResponse>;
          result.messages.replace(valueDes);
          break;
        case r'report_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.reportCount = valueDes;
          break;
        case r'is_repeat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isRepeat = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BusinessReportResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BusinessReportResponseBuilder();
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

