// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_place_link_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GooglePlaceLinkResponse extends GooglePlaceLinkResponse {
  @override
  final bool linked;
  @override
  final String placeId;

  factory _$GooglePlaceLinkResponse(
          [void Function(GooglePlaceLinkResponseBuilder)? updates]) =>
      (GooglePlaceLinkResponseBuilder()..update(updates))._build();

  _$GooglePlaceLinkResponse._({required this.linked, required this.placeId})
      : super._();
  @override
  GooglePlaceLinkResponse rebuild(
          void Function(GooglePlaceLinkResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GooglePlaceLinkResponseBuilder toBuilder() =>
      GooglePlaceLinkResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GooglePlaceLinkResponse &&
        linked == other.linked &&
        placeId == other.placeId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, linked.hashCode);
    _$hash = $jc(_$hash, placeId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GooglePlaceLinkResponse')
          ..add('linked', linked)
          ..add('placeId', placeId))
        .toString();
  }
}

class GooglePlaceLinkResponseBuilder
    implements
        Builder<GooglePlaceLinkResponse, GooglePlaceLinkResponseBuilder> {
  _$GooglePlaceLinkResponse? _$v;

  bool? _linked;
  bool? get linked => _$this._linked;
  set linked(bool? linked) => _$this._linked = linked;

  String? _placeId;
  String? get placeId => _$this._placeId;
  set placeId(String? placeId) => _$this._placeId = placeId;

  GooglePlaceLinkResponseBuilder() {
    GooglePlaceLinkResponse._defaults(this);
  }

  GooglePlaceLinkResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _linked = $v.linked;
      _placeId = $v.placeId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GooglePlaceLinkResponse other) {
    _$v = other as _$GooglePlaceLinkResponse;
  }

  @override
  void update(void Function(GooglePlaceLinkResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GooglePlaceLinkResponse build() => _build();

  _$GooglePlaceLinkResponse _build() {
    final _$result = _$v ??
        _$GooglePlaceLinkResponse._(
          linked: BuiltValueNullFieldError.checkNotNull(
              linked, r'GooglePlaceLinkResponse', 'linked'),
          placeId: BuiltValueNullFieldError.checkNotNull(
              placeId, r'GooglePlaceLinkResponse', 'placeId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
