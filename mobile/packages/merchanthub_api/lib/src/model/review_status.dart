//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_status.g.dart';

class ReviewStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'active')
  static const ReviewStatus active = _$active;
  @BuiltValueEnumConst(wireName: r'hidden')
  static const ReviewStatus hidden = _$hidden;
  @BuiltValueEnumConst(wireName: r'reported')
  static const ReviewStatus reported = _$reported;
  @BuiltValueEnumConst(wireName: r'removed')
  static const ReviewStatus removed = _$removed;

  static Serializer<ReviewStatus> get serializer => _$reviewStatusSerializer;

  const ReviewStatus._(String name): super(name);

  static BuiltSet<ReviewStatus> get values => _$values;
  static ReviewStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ReviewStatusMixin = Object with _$ReviewStatusMixin;

