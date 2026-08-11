// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FavoriteResponse extends FavoriteResponse {
  @override
  final bool favorited;
  @override
  final String businessId;

  factory _$FavoriteResponse(
          [void Function(FavoriteResponseBuilder)? updates]) =>
      (FavoriteResponseBuilder()..update(updates))._build();

  _$FavoriteResponse._({required this.favorited, required this.businessId})
      : super._();
  @override
  FavoriteResponse rebuild(void Function(FavoriteResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FavoriteResponseBuilder toBuilder() =>
      FavoriteResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FavoriteResponse &&
        favorited == other.favorited &&
        businessId == other.businessId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, favorited.hashCode);
    _$hash = $jc(_$hash, businessId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FavoriteResponse')
          ..add('favorited', favorited)
          ..add('businessId', businessId))
        .toString();
  }
}

class FavoriteResponseBuilder
    implements Builder<FavoriteResponse, FavoriteResponseBuilder> {
  _$FavoriteResponse? _$v;

  bool? _favorited;
  bool? get favorited => _$this._favorited;
  set favorited(bool? favorited) => _$this._favorited = favorited;

  String? _businessId;
  String? get businessId => _$this._businessId;
  set businessId(String? businessId) => _$this._businessId = businessId;

  FavoriteResponseBuilder() {
    FavoriteResponse._defaults(this);
  }

  FavoriteResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _favorited = $v.favorited;
      _businessId = $v.businessId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FavoriteResponse other) {
    _$v = other as _$FavoriteResponse;
  }

  @override
  void update(void Function(FavoriteResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FavoriteResponse build() => _build();

  _$FavoriteResponse _build() {
    final _$result = _$v ??
        _$FavoriteResponse._(
          favorited: BuiltValueNullFieldError.checkNotNull(
              favorited, r'FavoriteResponse', 'favorited'),
          businessId: BuiltValueNullFieldError.checkNotNull(
              businessId, r'FavoriteResponse', 'businessId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
