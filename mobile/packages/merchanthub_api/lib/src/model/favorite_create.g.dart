// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FavoriteCreate extends FavoriteCreate {
  @override
  final String businessId;

  factory _$FavoriteCreate([void Function(FavoriteCreateBuilder)? updates]) =>
      (FavoriteCreateBuilder()..update(updates))._build();

  _$FavoriteCreate._({required this.businessId}) : super._();
  @override
  FavoriteCreate rebuild(void Function(FavoriteCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FavoriteCreateBuilder toBuilder() => FavoriteCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FavoriteCreate && businessId == other.businessId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FavoriteCreate')
          ..add('businessId', businessId))
        .toString();
  }
}

class FavoriteCreateBuilder
    implements Builder<FavoriteCreate, FavoriteCreateBuilder> {
  _$FavoriteCreate? _$v;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  FavoriteCreateBuilder() {
    FavoriteCreate._defaults(this);
  }

  FavoriteCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _businessId = $v.businessId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FavoriteCreate other) {
    _$v = other as _$FavoriteCreate;
  }

  @override
  void update(void Function(FavoriteCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FavoriteCreate build() => _build();

  _$FavoriteCreate _build() {
    final _$result = _$v ??
        _$FavoriteCreate._(
          businessId: BuiltValueNullFieldError.checkNotNull(
              businessId, r'FavoriteCreate', 'businessId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
