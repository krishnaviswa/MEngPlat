// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_business_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NearbyBusinessRequest extends NearbyBusinessRequest {
  @override
  final num lat;
  @override
  final num lng;
  @override
  final num? radiusKm;

  factory _$NearbyBusinessRequest(
          [void Function(NearbyBusinessRequestBuilder)? updates]) =>
      (NearbyBusinessRequestBuilder()..update(updates))._build();

  _$NearbyBusinessRequest._(
      {required this.lat, required this.lng, this.radiusKm})
      : super._();
  @override
  NearbyBusinessRequest rebuild(
          void Function(NearbyBusinessRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NearbyBusinessRequestBuilder toBuilder() =>
      NearbyBusinessRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NearbyBusinessRequest &&
        lat == other.lat &&
        lng == other.lng &&
        radiusKm == other.radiusKm;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, lng.hashCode);
    _$hash = $jc(_$hash, radiusKm.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NearbyBusinessRequest')
          ..add('lat', lat)
          ..add('lng', lng)
          ..add('radiusKm', radiusKm))
        .toString();
  }
}

class NearbyBusinessRequestBuilder
    implements Builder<NearbyBusinessRequest, NearbyBusinessRequestBuilder> {
  _$NearbyBusinessRequest? _$v;

  num? _lat;
  num? get lat => _$this._lat;
  set lat(num? lat) => _$this._lat = lat;

  num? _lng;
  num? get lng => _$this._lng;
  set lng(num? lng) => _$this._lng = lng;

  num? _radiusKm;
  num? get radiusKm => _$this._radiusKm;
  set radiusKm(num? radiusKm) => _$this._radiusKm = radiusKm;

  NearbyBusinessRequestBuilder() {
    NearbyBusinessRequest._defaults(this);
  }

  NearbyBusinessRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lat = $v.lat;
      _lng = $v.lng;
      _radiusKm = $v.radiusKm;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NearbyBusinessRequest other) {
    _$v = other as _$NearbyBusinessRequest;
  }

  @override
  void update(void Function(NearbyBusinessRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NearbyBusinessRequest build() => _build();

  _$NearbyBusinessRequest _build() {
    final _$result = _$v ??
        _$NearbyBusinessRequest._(
          lat: BuiltValueNullFieldError.checkNotNull(
              lat, r'NearbyBusinessRequest', 'lat'),
          lng: BuiltValueNullFieldError.checkNotNull(
              lng, r'NearbyBusinessRequest', 'lng'),
          radiusKm: radiusKm,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
