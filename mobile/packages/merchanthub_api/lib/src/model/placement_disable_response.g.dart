// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placement_disable_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlacementDisableResponse extends PlacementDisableResponse {
  @override
  final String id;
  @override
  final DateTime disabledAt;

  factory _$PlacementDisableResponse(
          [void Function(PlacementDisableResponseBuilder)? updates]) =>
      (PlacementDisableResponseBuilder()..update(updates))._build();

  _$PlacementDisableResponse._({required this.id, required this.disabledAt})
      : super._();
  @override
  PlacementDisableResponse rebuild(
          void Function(PlacementDisableResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlacementDisableResponseBuilder toBuilder() =>
      PlacementDisableResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlacementDisableResponse &&
        id == other.id &&
        disabledAt == other.disabledAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, disabledAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlacementDisableResponse')
          ..add('id', id)
          ..add('disabledAt', disabledAt))
        .toString();
  }
}

class PlacementDisableResponseBuilder
    implements
        Builder<PlacementDisableResponse, PlacementDisableResponseBuilder> {
  _$PlacementDisableResponse? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _disabledAt;
  DateTime? get disabledAt => _$this._disabledAt;
  set disabledAt(DateTime? disabledAt) => _$this._disabledAt = disabledAt;

  PlacementDisableResponseBuilder() {
    PlacementDisableResponse._defaults(this);
  }

  PlacementDisableResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _disabledAt = $v.disabledAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlacementDisableResponse other) {
    _$v = other as _$PlacementDisableResponse;
  }

  @override
  void update(void Function(PlacementDisableResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlacementDisableResponse build() => _build();

  _$PlacementDisableResponse _build() {
    final _$result = _$v ??
        _$PlacementDisableResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PlacementDisableResponse', 'id'),
          disabledAt: BuiltValueNullFieldError.checkNotNull(
              disabledAt, r'PlacementDisableResponse', 'disabledAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
