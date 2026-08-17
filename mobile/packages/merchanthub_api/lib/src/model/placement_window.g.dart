// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placement_window.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlacementWindow extends PlacementWindow {
  @override
  final String id;
  @override
  final DateTime startsAt;
  @override
  final DateTime endsAt;
  @override
  final DateTime? disabledAt;
  @override
  final String paymentId;

  factory _$PlacementWindow([void Function(PlacementWindowBuilder)? updates]) =>
      (PlacementWindowBuilder()..update(updates))._build();

  _$PlacementWindow._(
      {required this.id,
      required this.startsAt,
      required this.endsAt,
      this.disabledAt,
      required this.paymentId})
      : super._();
  @override
  PlacementWindow rebuild(void Function(PlacementWindowBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlacementWindowBuilder toBuilder() => PlacementWindowBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlacementWindow &&
        id == other.id &&
        startsAt == other.startsAt &&
        endsAt == other.endsAt &&
        disabledAt == other.disabledAt &&
        paymentId == other.paymentId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, endsAt.hashCode);
    _$hash = $jc(_$hash, disabledAt.hashCode);
    _$hash = $jc(_$hash, paymentId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlacementWindow')
          ..add('id', id)
          ..add('startsAt', startsAt)
          ..add('endsAt', endsAt)
          ..add('disabledAt', disabledAt)
          ..add('paymentId', paymentId))
        .toString();
  }
}

class PlacementWindowBuilder
    implements Builder<PlacementWindow, PlacementWindowBuilder> {
  _$PlacementWindow? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _startsAt;
  DateTime? get startsAt => _$this._startsAt;
  set startsAt(DateTime? startsAt) => _$this._startsAt = startsAt;

  DateTime? _endsAt;
  DateTime? get endsAt => _$this._endsAt;
  set endsAt(DateTime? endsAt) => _$this._endsAt = endsAt;

  DateTime? _disabledAt;
  DateTime? get disabledAt => _$this._disabledAt;
  set disabledAt(DateTime? disabledAt) => _$this._disabledAt = disabledAt;

  String? _paymentId;
  String? get paymentId => _$this._paymentId;
  set paymentId(String? paymentId) => _$this._paymentId = paymentId;

  PlacementWindowBuilder() {
    PlacementWindow._defaults(this);
  }

  PlacementWindowBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _startsAt = $v.startsAt;
      _endsAt = $v.endsAt;
      _disabledAt = $v.disabledAt;
      _paymentId = $v.paymentId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlacementWindow other) {
    _$v = other as _$PlacementWindow;
  }

  @override
  void update(void Function(PlacementWindowBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlacementWindow build() => _build();

  _$PlacementWindow _build() {
    final _$result = _$v ??
        _$PlacementWindow._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PlacementWindow', 'id'),
          startsAt: BuiltValueNullFieldError.checkNotNull(
              startsAt, r'PlacementWindow', 'startsAt'),
          endsAt: BuiltValueNullFieldError.checkNotNull(
              endsAt, r'PlacementWindow', 'endsAt'),
          disabledAt: disabledAt,
          paymentId: BuiltValueNullFieldError.checkNotNull(
              paymentId, r'PlacementWindow', 'paymentId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
