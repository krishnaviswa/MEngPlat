// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_place_candidate_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GooglePlaceCandidateResponse extends GooglePlaceCandidateResponse {
  @override
  final String placeId;
  @override
  final String name;
  @override
  final String address;
  @override
  final num latitude;
  @override
  final num longitude;

  factory _$GooglePlaceCandidateResponse(
          [void Function(GooglePlaceCandidateResponseBuilder)? updates]) =>
      (GooglePlaceCandidateResponseBuilder()..update(updates))._build();

  _$GooglePlaceCandidateResponse._(
      {required this.placeId,
      required this.name,
      required this.address,
      required this.latitude,
      required this.longitude})
      : super._();
  @override
  GooglePlaceCandidateResponse rebuild(
          void Function(GooglePlaceCandidateResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GooglePlaceCandidateResponseBuilder toBuilder() =>
      GooglePlaceCandidateResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GooglePlaceCandidateResponse &&
        placeId == other.placeId &&
        name == other.name &&
        address == other.address &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, placeId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GooglePlaceCandidateResponse')
          ..add('placeId', placeId)
          ..add('name', name)
          ..add('address', address)
          ..add('latitude', latitude)
          ..add('longitude', longitude))
        .toString();
  }
}

class GooglePlaceCandidateResponseBuilder
    implements
        Builder<GooglePlaceCandidateResponse,
            GooglePlaceCandidateResponseBuilder> {
  _$GooglePlaceCandidateResponse? _$v;

  String? _placeId;
  String? get placeId => _$this._placeId;
  set placeId(String? placeId) => _$this._placeId = placeId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  GooglePlaceCandidateResponseBuilder() {
    GooglePlaceCandidateResponse._defaults(this);
  }

  GooglePlaceCandidateResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _placeId = $v.placeId;
      _name = $v.name;
      _address = $v.address;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GooglePlaceCandidateResponse other) {
    _$v = other as _$GooglePlaceCandidateResponse;
  }

  @override
  void update(void Function(GooglePlaceCandidateResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GooglePlaceCandidateResponse build() => _build();

  _$GooglePlaceCandidateResponse _build() {
    final _$result = _$v ??
        _$GooglePlaceCandidateResponse._(
          placeId: BuiltValueNullFieldError.checkNotNull(
              placeId, r'GooglePlaceCandidateResponse', 'placeId'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'GooglePlaceCandidateResponse', 'name'),
          address: BuiltValueNullFieldError.checkNotNull(
              address, r'GooglePlaceCandidateResponse', 'address'),
          latitude: BuiltValueNullFieldError.checkNotNull(
              latitude, r'GooglePlaceCandidateResponse', 'latitude'),
          longitude: BuiltValueNullFieldError.checkNotNull(
              longitude, r'GooglePlaceCandidateResponse', 'longitude'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
