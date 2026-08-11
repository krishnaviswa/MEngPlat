//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_profile_update.g.dart';

/// Self-service PATCH /auth/me payload. Only full_name / avatar_url are editable; email, role, and is_active are omitted so extra body keys are silently dropped.
///
/// Properties:
/// * [fullName] 
/// * [avatarUrl] 
@BuiltValue()
abstract class UserProfileUpdate implements Built<UserProfileUpdate, UserProfileUpdateBuilder> {
  @BuiltValueField(wireName: r'full_name')
  String? get fullName;

  @BuiltValueField(wireName: r'avatar_url')
  String? get avatarUrl;

  UserProfileUpdate._();

  factory UserProfileUpdate([void updates(UserProfileUpdateBuilder b)]) = _$UserProfileUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserProfileUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserProfileUpdate> get serializer => _$UserProfileUpdateSerializer();
}

class _$UserProfileUpdateSerializer implements PrimitiveSerializer<UserProfileUpdate> {
  @override
  final Iterable<Type> types = const [UserProfileUpdate, _$UserProfileUpdate];

  @override
  final String wireName = r'UserProfileUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserProfileUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.fullName != null) {
      yield r'full_name';
      yield serializers.serialize(
        object.fullName,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.avatarUrl != null) {
      yield r'avatar_url';
      yield serializers.serialize(
        object.avatarUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UserProfileUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserProfileUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'full_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.fullName = valueDes;
          break;
        case r'avatar_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.avatarUrl = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UserProfileUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserProfileUpdateBuilder();
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

