// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geocode_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GeocodeResponse extends GeocodeResponse {
  @override
  final String message;
  @override
  final num? latitude;
  @override
  final num? longitude;
  @override
  final String? displayName;

  factory _$GeocodeResponse([void Function(GeocodeResponseBuilder)? updates]) =>
      (GeocodeResponseBuilder()..update(updates))._build();

  _$GeocodeResponse._(
      {required this.message, this.latitude, this.longitude, this.displayName})
      : super._();
  @override
  GeocodeResponse rebuild(void Function(GeocodeResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GeocodeResponseBuilder toBuilder() => GeocodeResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GeocodeResponse &&
        message == other.message &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GeocodeResponse')
          ..add('message', message)
          ..add('latitude', latitude)
          ..add('longitude', longitude)
          ..add('displayName', displayName))
        .toString();
  }
}

class GeocodeResponseBuilder
    implements Builder<GeocodeResponse, GeocodeResponseBuilder> {
  _$GeocodeResponse? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  GeocodeResponseBuilder() {
    GeocodeResponse._defaults(this);
  }

  GeocodeResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GeocodeResponse other) {
    _$v = other as _$GeocodeResponse;
  }

  @override
  void update(void Function(GeocodeResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GeocodeResponse build() => _build();

  _$GeocodeResponse _build() {
    final _$result = _$v ??
        _$GeocodeResponse._(
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'GeocodeResponse', 'message'),
          latitude: latitude,
          longitude: longitude,
          displayName: displayName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
