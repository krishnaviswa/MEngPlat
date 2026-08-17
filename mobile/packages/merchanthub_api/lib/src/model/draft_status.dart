//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'draft_status.g.dart';

class DraftStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'pending')
  static const DraftStatus pending = _$pending;
  @BuiltValueEnumConst(wireName: r'applied')
  static const DraftStatus applied = _$applied;
  @BuiltValueEnumConst(wireName: r'discarded')
  static const DraftStatus discarded = _$discarded;

  static Serializer<DraftStatus> get serializer => _$draftStatusSerializer;

  const DraftStatus._(String name): super(name);

  static BuiltSet<DraftStatus> get values => _$values;
  static DraftStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DraftStatusMixin = Object with _$DraftStatusMixin;

