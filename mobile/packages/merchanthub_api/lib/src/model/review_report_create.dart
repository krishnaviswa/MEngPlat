//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_report_create.g.dart';

/// ReviewReportCreate
///
/// Properties:
/// * [reason] 
@BuiltValue()
abstract class ReviewReportCreate implements Built<ReviewReportCreate, ReviewReportCreateBuilder> {
  @BuiltValueField(wireName: r'reason')
  String get reason;

  ReviewReportCreate._();

  factory ReviewReportCreate([void updates(ReviewReportCreateBuilder b)]) = _$ReviewReportCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReviewReportCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReviewReportCreate> get serializer => _$ReviewReportCreateSerializer();
}

class _$ReviewReportCreateSerializer implements PrimitiveSerializer<ReviewReportCreate> {
  @override
  final Iterable<Type> types = const [ReviewReportCreate, _$ReviewReportCreate];

  @override
  final String wireName = r'ReviewReportCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReviewReportCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReviewReportCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReviewReportCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReviewReportCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReviewReportCreateBuilder();
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

