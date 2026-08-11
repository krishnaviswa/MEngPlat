//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:merchanthub_api/src/model/ai_analysis_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'photo_response.g.dart';

/// PhotoResponse
///
/// Properties:
/// * [id] 
/// * [url] 
/// * [caption] 
/// * [photoType] 
/// * [aiAnalysis] 
@BuiltValue()
abstract class PhotoResponse implements Built<PhotoResponse, PhotoResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'url')
  String get url;

  @BuiltValueField(wireName: r'caption')
  String? get caption;

  @BuiltValueField(wireName: r'photo_type')
  String get photoType;

  @BuiltValueField(wireName: r'ai_analysis')
  AIAnalysisResponse? get aiAnalysis;

  PhotoResponse._();

  factory PhotoResponse([void updates(PhotoResponseBuilder b)]) = _$PhotoResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhotoResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhotoResponse> get serializer => _$PhotoResponseSerializer();
}

class _$PhotoResponseSerializer implements PrimitiveSerializer<PhotoResponse> {
  @override
  final Iterable<Type> types = const [PhotoResponse, _$PhotoResponse];

  @override
  final String wireName = r'PhotoResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhotoResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'url';
    yield serializers.serialize(
      object.url,
      specifiedType: const FullType(String),
    );
    if (object.caption != null) {
      yield r'caption';
      yield serializers.serialize(
        object.caption,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'photo_type';
    yield serializers.serialize(
      object.photoType,
      specifiedType: const FullType(String),
    );
    if (object.aiAnalysis != null) {
      yield r'ai_analysis';
      yield serializers.serialize(
        object.aiAnalysis,
        specifiedType: const FullType(AIAnalysisResponse),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PhotoResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhotoResponseBuilder result,
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
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.url = valueDes;
          break;
        case r'caption':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.caption = valueDes;
          break;
        case r'photo_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.photoType = valueDes;
          break;
        case r'ai_analysis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AIAnalysisResponse),
          ) as AIAnalysisResponse;
          result.aiAnalysis.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhotoResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhotoResponseBuilder();
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

